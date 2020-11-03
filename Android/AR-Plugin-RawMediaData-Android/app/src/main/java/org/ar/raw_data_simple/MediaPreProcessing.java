package org.ar.raw_data_simple;

import android.graphics.Bitmap;

import java.nio.ByteBuffer;

public class MediaPreProcessing {


    static {
        System.loadLibrary("apm-plugin-raw-data");
    }




    public interface ProgressCallback {
        void onCaptureVideoFrame(int videoFrameType, int width, int height, int bufferLength, int yStride, int uStride, int vStride, int rotation, long renderTimeMs);
    }

    public interface VideoOnserver{
        void onCaptureVideoFrame(Bitmap bitmap);
    }

    public static native void setCallback(ProgressCallback callback);

    public static native void setVideoCaptureByteBuffer(ByteBuffer byteBuffer);

    public static native void setAudioRecordByteBuffer(ByteBuffer byteBuffer);

    public static native void setAudioPlayByteBuffer(ByteBuffer byteBuffer);

    public static native void setBeforeAudioMixByteBuffer(ByteBuffer byteBuffer);

    public static native void setAudioMixByteBuffer(ByteBuffer byteBuffer);

    public static native void setVideoDecodeByteBuffer(String uid, ByteBuffer byteBuffer);

    public static native void releasePoint();

}
