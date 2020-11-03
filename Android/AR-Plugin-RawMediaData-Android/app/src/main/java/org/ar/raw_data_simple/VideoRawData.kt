package org.ar.raw_data_simple

import android.graphics.Bitmap
import org.ar.rtc.RtcEngine
import java.nio.ByteBuffer

class VideoRawData {
    private val byteBufferCapture: ByteBuffer = ByteBuffer.allocateDirect(3240 * 1080) // default maximum video size Full HD+

    init {
        System.loadLibrary("apm-plugin-raw-data")
    }

    fun subscribe(observer: VideoObserver) {
        setVideoCaptureByteBuffer(byteBufferCapture)
        setCallback(
                object : RawDataCallback {
                    override fun onCaptureVideoFrame(
                            videoFrameType: Int,
                            width: Int,
                            height: Int,
                            bufferLength: Int,
                            yStride: Int,
                            uStride: Int,
                            vStride: Int,
                            rotation: Int,
                            renderTimeMs: Long
                    ) {
                        val buffer = ByteArray(bufferLength)
                        byteBufferCapture.limit(bufferLength)
                        byteBufferCapture.get(buffer)
                        byteBufferCapture.flip()
                        val bmp = YUVUtils.i420ToBitmap(
                                width,
                                height,
                                rotation,
                                bufferLength,
                                buffer,
                                yStride
                        )
                        observer.onCaptureVideoFrame(bmp)
                        byteBufferCapture.put(buffer)
                        byteBufferCapture.flip()
                    }
                }
        )
    }

    fun unsubscribe() {
        byteBufferCapture.clear()
        releasePoint()
    }

    private interface RawDataCallback {
        fun onCaptureVideoFrame(
                videoFrameType: Int,
                width: Int,
                height: Int,
                bufferLength: Int,
                yStride: Int,
                uStride: Int,
                vStride: Int,
                rotation: Int,
                renderTimeMs: Long
        )
    }

    fun setEngine( engine:RtcEngine){
        nativeSetEngine(engine.nativehanlde)
    }

    interface VideoObserver {
        fun onCaptureVideoFrame(bitmap: Bitmap)
    }

    private external fun nativeSetEngine(nativeId: Long)

    private external fun setCallback(callback: RawDataCallback)

    private external fun setVideoCaptureByteBuffer(byteBuffer: ByteBuffer)

    private external fun releasePoint()
}