package com.host4.host4_flutter_device_native

import android.content.Context
import com.host4.platform.kr.response.EscalationRsp
import com.host4.platform.listener.OnEscalationListener
import com.host4.platform.listener.UsbConnectListener
import com.host4.platform.manager.ReliableUsbCommManager
import com.host4.platform.v2.api.UsbDeviceSessionHandle

/**
 * USB 连接辅助类，封装 SDK 初始化与释放。
 *
 * 标准连接流程：
 * 1. [registerListeners] — 注册连接状态与上报监听（需在 init 之前）
 * 2. [initUsbPidVid] — 按 pid/vid 筛选并初始化 USB Host（进程内仅一次）
 * 3. SDK 内部自动申请权限、监听插拔并连接设备
 */
internal class UsbConnectionHelper(
    private val applicationContext: Context,
) {
    @Volatile
    var initialized: Boolean = false
        private set

    /**
     * 注册 USB 连接状态与上报监听。
     * 每次新建传输会话时都需调用，确保回调指向当前会话。
     */
    fun registerListeners(
        usbHandle: UsbDeviceSessionHandle,
        connectListener: UsbConnectListener,
        escalationListener: OnEscalationListener<EscalationRsp>,
    ) {
        usbHandle.setUsbConnectListener(connectListener)
        usbHandle.registerAllEscalationListener(escalationListener)
    }

    /**
     * 初始化 USB Host 并按 pid/vid 筛选目标设备。
     *
     * 对应 SDK：
     * - [UsbDeviceSessionHandle.init] / [ReliableUsbCommManager.init]
     * - CommunicateController.initUsbPidVid(context, pids, vids)
     *
     * @param filter pid/vid 筛选条件；均为空时不限制设备
     */
    fun initUsbPidVid(usbHandle: UsbDeviceSessionHandle, filter: UsbPidVidFilter) {
        if (initialized) {
            return
        }

        when {
            filter.hasSinglePair -> {
                usbHandle.init(applicationContext, filter.singlePid!!, filter.singleVid!!)
            }
            filter.hasArrayFilter -> {
                usbHandle.init(
                    applicationContext,
                    filter.pids?.takeIf { it.isNotEmpty() },
                    filter.vids?.takeIf { it.isNotEmpty() },
                )
            }
            else -> {
                usbHandle.init(applicationContext)
            }
        }
        initialized = true
    }

    /** 若设备在订阅事件前已连接，补发 ready 状态 */
    fun syncConnectedState(onReady: () -> Unit) {
        if (ReliableUsbCommManager.getInstance().isConnected) {
            onReady()
        }
    }

    /** 重新搜索并连接 USB 设备（设备拔出重插后调用） */
    fun reconnect() {
        ReliableUsbCommManager.getInstance().searchAndConnectAsync()
    }

    /** 断开 USB 并释放 Host 资源 */
    fun release(usbHandle: UsbDeviceSessionHandle) {
        if (!initialized) {
            return
        }
        runCatching { usbHandle.disconnect() }
        initialized = false
    }
}
