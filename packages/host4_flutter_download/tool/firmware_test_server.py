#!/usr/bin/env python3
"""Local firmware HTTP server for range/no-range download testing."""

from __future__ import annotations

import argparse
import csv
import posixpath
import sys
import time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import BinaryIO
from urllib.parse import unquote, urlsplit


DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 18080
DEFAULT_CHUNK_SIZE = 64 * 1024


class FirmwareRequestHandler(BaseHTTPRequestHandler):
    server: "FirmwareHTTPServer"

    def do_HEAD(self) -> None:
        self._serve(send_body=False)

    def do_GET(self) -> None:
        self._serve(send_body=True)

    def log_message(self, fmt: str, *args: object) -> None:
        if self.server.verbose:
            super().log_message(fmt, *args)

    def _serve(self, *, send_body: bool) -> None:
        try:
            target = self._resolve_path()
        except ValueError:
            self._send_status(HTTPStatus.FORBIDDEN)
            return

        if not target.is_file():
            self._send_status(HTTPStatus.NOT_FOUND)
            return

        file_size = target.stat().st_size
        range_header = self.headers.get("Range")
        response = _range_response(
            range_header=range_header,
            file_size=file_size,
            mode=self.server.mode,
        )

        if response is None:
            self._send_status(HTTPStatus.REQUESTED_RANGE_NOT_SATISFIABLE)
            return

        status, start, end = response
        length = end - start + 1
        self.send_response(status)
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(length))
        if status == HTTPStatus.PARTIAL_CONTENT:
            self.send_header(
                "Content-Range",
                f"bytes {start}-{end}/{file_size}",
            )
        self.end_headers()
        self._write_request_log(status)

        if send_body:
            with target.open("rb") as file:
                file.seek(start)
                self._copy_bytes(file, length)

    def _resolve_path(self) -> Path:
        raw_path = unquote(urlsplit(self.path).path)
        segments = [segment for segment in raw_path.split("/") if segment]
        if any(segment == ".." for segment in segments):
            raise ValueError("path traversal is not allowed")

        normalized = posixpath.normpath(raw_path)
        if normalized in ("", ".", "/"):
            raise ValueError("directory listing is disabled")
        if raw_path.endswith("/") or normalized.startswith("../"):
            raise ValueError("path traversal is not allowed")

        relative = normalized.lstrip("/")
        if not relative or relative.startswith("../") or "/../" in f"/{relative}/":
            raise ValueError("path traversal is not allowed")

        candidate = (self.server.root / relative).resolve()
        try:
            candidate.relative_to(self.server.root)
        except ValueError as exc:
            raise ValueError("path traversal is not allowed") from exc
        return candidate

    def _send_status(self, status: HTTPStatus) -> None:
        self.send_response(status)
        self.send_header("Content-Length", "0")
        self.end_headers()
        self._write_request_log(status)

    def _copy_bytes(self, file: BinaryIO, length: int) -> None:
        remaining = length
        while remaining > 0:
            chunk = file.read(min(self.server.chunk_size, remaining))
            if not chunk:
                break
            try:
                self.wfile.write(chunk)
                self.wfile.flush()
            except BrokenPipeError:
                break
            remaining -= len(chunk)
            if self.server.chunk_delay_ms > 0 and remaining > 0:
                time.sleep(self.server.chunk_delay_ms / 1000)

    def _write_request_log(self, status: HTTPStatus) -> None:
        log_path = self.server.request_log
        if log_path is None:
            return

        log_path.parent.mkdir(parents=True, exist_ok=True)
        exists = log_path.exists()
        with log_path.open("a", newline="", encoding="utf-8") as file:
            writer = csv.DictWriter(
                file,
                fieldnames=["method", "path", "range", "status"],
            )
            if not exists:
                writer.writeheader()
            writer.writerow(
                {
                    "method": self.command,
                    "path": urlsplit(self.path).path,
                    "range": self.headers.get("Range", ""),
                    "status": int(status),
                }
            )


class FirmwareHTTPServer(ThreadingHTTPServer):
    def __init__(
        self,
        server_address: tuple[str, int],
        *,
        root: Path,
        mode: str,
        chunk_size: int,
        chunk_delay_ms: int,
        request_log: Path | None,
        verbose: bool,
    ) -> None:
        super().__init__(server_address, FirmwareRequestHandler)
        self.root = root
        self.mode = mode
        self.chunk_size = chunk_size
        self.chunk_delay_ms = chunk_delay_ms
        self.request_log = request_log
        self.verbose = verbose


def _range_response(
    *,
    range_header: str | None,
    file_size: int,
    mode: str,
) -> tuple[HTTPStatus, int, int] | None:
    if file_size <= 0:
        return (HTTPStatus.OK, 0, -1)

    if mode == "no-range" or not range_header:
        return (HTTPStatus.OK, 0, file_size - 1)

    parsed = _parse_byte_range(range_header, file_size)
    if parsed is None:
        return None

    start, end = parsed
    return (HTTPStatus.PARTIAL_CONTENT, start, end)


def _parse_byte_range(
    range_header: str,
    file_size: int,
) -> tuple[int, int] | None:
    if not range_header.startswith("bytes="):
        return None

    range_value = range_header.removeprefix("bytes=").strip()
    if "," in range_value or "-" not in range_value:
        return None

    start_text, end_text = range_value.split("-", 1)
    if not start_text:
        suffix_length = _parse_positive_int(end_text)
        if suffix_length is None:
            return None
        start = max(file_size - suffix_length, 0)
        return (start, file_size - 1)

    start = _parse_non_negative_int(start_text)
    if start is None or start >= file_size:
        return None

    if not end_text:
        return (start, file_size - 1)

    end = _parse_non_negative_int(end_text)
    if end is None or end < start:
        return None
    return (start, min(end, file_size - 1))


def _parse_non_negative_int(value: str) -> int | None:
    if not value.isdigit():
        return None
    return int(value)


def _parse_positive_int(value: str) -> int | None:
    parsed = _parse_non_negative_int(value)
    if parsed is None or parsed <= 0:
        return None
    return parsed


def _default_root() -> Path:
    return Path(__file__).resolve().parent / "firmware-fixtures"


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Serve firmware fixtures with explicit range/no-range modes.",
    )
    parser.add_argument("--host", default=DEFAULT_HOST)
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument("--root", type=Path, default=_default_root())
    parser.add_argument("--mode", choices=["range", "no-range"], default="range")
    parser.add_argument("--chunk-size", type=int, default=DEFAULT_CHUNK_SIZE)
    parser.add_argument("--chunk-delay-ms", type=int, default=0)
    parser.add_argument("--request-log", type=Path)
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args(argv)
    if args.chunk_size <= 0:
        parser.error("--chunk-size must be greater than 0")
    if args.chunk_delay_ms < 0:
        parser.error("--chunk-delay-ms must be greater than or equal to 0")
    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    root = args.root.resolve()
    if not root.is_dir():
        print(f"fixture root does not exist: {root}", file=sys.stderr)
        return 2

    server = FirmwareHTTPServer(
        (args.host, args.port),
        root=root,
        mode=args.mode,
        chunk_size=args.chunk_size,
        chunk_delay_ms=args.chunk_delay_ms,
        request_log=args.request_log.resolve() if args.request_log else None,
        verbose=args.verbose,
    )
    print(
        f"serving {root} on http://{args.host}:{server.server_port} "
        f"mode={args.mode}",
        flush=True,
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
