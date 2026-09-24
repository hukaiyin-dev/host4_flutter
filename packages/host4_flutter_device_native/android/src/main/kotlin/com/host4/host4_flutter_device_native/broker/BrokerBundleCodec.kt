package com.host4.host4_flutter_device_native.broker

import android.os.Bundle

object BrokerBundleCodec {
    fun toBundle(map: Map<String, Any?>?): Bundle {
        val bundle = Bundle()
        if (map == null) {
            return bundle
        }
        for ((key, value) in map) {
            putValue(bundle, key, value)
        }
        return bundle
    }

    fun toMap(bundle: Bundle?): Map<String, Any?> {
        if (bundle == null) {
            return emptyMap()
        }
        val result = linkedMapOf<String, Any?>()
        for (key in bundle.keySet()) {
            result[key] = fromValue(getRaw(bundle, key))
        }
        return result
    }

    private fun putValue(bundle: Bundle, key: String, value: Any?) {
        when (value) {
            null -> bundle.putString(key, null)
            is Boolean -> bundle.putBoolean(key, value)
            is Byte -> bundle.putByte(key, value)
            is Short -> bundle.putShort(key, value)
            is Int -> bundle.putInt(key, value)
            is Long -> bundle.putLong(key, value)
            is Float -> bundle.putFloat(key, value)
            is Double -> bundle.putDouble(key, value)
            is String -> bundle.putString(key, value)
            is ByteArray -> bundle.putByteArray(key, value)
            is IntArray -> bundle.putIntArray(key, value)
            is Bundle -> bundle.putBundle(key, value)
            is Map<*, *> -> {
                @Suppress("UNCHECKED_CAST")
                bundle.putBundle(key, toBundle(value as Map<String, Any?>))
            }
            is List<*> -> putList(bundle, key, value)
            else -> bundle.putString(key, value.toString())
        }
    }

    private fun putList(bundle: Bundle, key: String, values: List<*>) {
        if (values.all { it is Int || it is Short || it is Byte }) {
            val ints = ArrayList<Int>(values.size)
            values.forEach { ints.add((it as Number).toInt()) }
            bundle.putIntegerArrayList(key, ints)
            return
        }
        if (values.all { it is String || it == null }) {
            val strings = ArrayList<String?>(values.size)
            values.forEach { strings.add(it as String?) }
            bundle.putStringArrayList(key, strings)
            return
        }
        val items = ArrayList<Bundle>(values.size)
        for (item in values) {
            items.add(wrapListItem(item))
        }
        bundle.putParcelableArrayList(key, items)
    }

    private fun wrapListItem(item: Any?): Bundle {
        if (item is Map<*, *>) {
            @Suppress("UNCHECKED_CAST")
            return toBundle(item as Map<String, Any?>)
        }
        val wrapped = Bundle()
        wrapped.putBoolean("__host4_list_item__", true)
        putValue(wrapped, "value", item)
        return wrapped
    }

    private fun fromValue(value: Any?): Any? {
        return when (value) {
            is Bundle -> unwrapBundle(value)
            is ArrayList<*> -> value.map { fromValue(it) }
            is IntArray -> value.toList()
            else -> value
        }
    }

    private fun unwrapBundle(bundle: Bundle): Any? {
        if (bundle.getBoolean("__host4_list_item__", false)) {
            return fromValue(getRaw(bundle, "value"))
        }
        return toMap(bundle)
    }

    private fun getRaw(bundle: Bundle, key: String): Any? {
        @Suppress("DEPRECATION")
        return bundle.get(key)
    }
}
