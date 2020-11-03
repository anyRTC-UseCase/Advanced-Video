package org.ar.raw_data_simple;

import android.Manifest;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import android.view.TextureView;
import android.view.View;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.Toast;

import org.ar.rtc.Constants;
import org.ar.rtc.IRtcEngineEventHandler;
import org.ar.rtc.RtcEngine;
import org.ar.rtc.video.VideoCanvas;
import org.jetbrains.annotations.NotNull;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

public class VideoActivity extends AppCompatActivity implements View.OnClickListener , VideoRawData.VideoObserver {

    private RelativeLayout rlLocal;
    private RelativeLayout rlRemote;
    private ImageView ivSwitch,ivMuteAudio,ivMuteVideo,ivCall,iv_bitmap;
    private String userId = String.valueOf((int) ((Math.random() * 9 + 1) * 100000));
    private RtcEngine mRtcEngine;
    private boolean mCallEnd;
    private String remoteId= "";
    private VideoRawData videoRawData;



    private static final int PERMISSION_REQ_ID = 22;
    private static final String[] REQUESTED_PERMISSIONS = {
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.CAMERA,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        rlLocal = findViewById(R.id.rl_local_video);
        rlRemote = findViewById(R.id.rl_remote_video);

        ivSwitch = findViewById(R.id.btn_switch_camera);
        ivCall = findViewById(R.id.btn_call);
        ivMuteAudio = findViewById(R.id.btn_audio_mute);
        ivMuteVideo = findViewById(R.id.btn_video_mute);

        iv_bitmap = findViewById(R.id.iv_bitmap);
        ivSwitch.setOnClickListener(this);
        ivCall.setOnClickListener(this);
        ivMuteAudio.setOnClickListener(this);
        ivMuteVideo.setOnClickListener(this);

        if (checkSelfPermission(REQUESTED_PERMISSIONS[0], PERMISSION_REQ_ID) &&
                checkSelfPermission(REQUESTED_PERMISSIONS[1], PERMISSION_REQ_ID) &&
                checkSelfPermission(REQUESTED_PERMISSIONS[2], PERMISSION_REQ_ID)) {
            initEngineAndJoinChannel();
        }


    }

    private void initEngineAndJoinChannel() {
        initializeEngine();
        setupLocalVideo();
        joinChannel();
    }

    private void initializeEngine() {
        try {
            //APPID 需要去anyRTC官网注册
            mRtcEngine = RtcEngine.create(getBaseContext(), getResources().getString(R.string.appId), mRtcEventHandler);
            //启用视频模块
            mRtcEngine.enableVideo();
            mRtcEngine.setDefaultAudioRoutetoSpeakerphone(true);
            videoRawData = new VideoRawData();
            videoRawData.setEngine(mRtcEngine);

        } catch (Exception e) {
            throw new RuntimeException("NEED TO check rtc sdk init fatal error\n" + Log.getStackTraceString(e));
        }
    }


    private void joinChannel() {
        mRtcEngine.joinChannel("", "100000", "Extra Optional Data",userId );
    }

    private void leaveChannel() {
        mRtcEngine.leaveChannel();
    }


    private final IRtcEngineEventHandler mRtcEventHandler = new IRtcEngineEventHandler() {
        @Override
        public void onJoinChannelSuccess(String channel, final String uid, int elapsed) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    logI("加入频道成功");
                    videoRawData.subscribe(VideoActivity.this::onCaptureVideoFrame);
                    showButtons(true);
                }
            });
        }

        @Override
        public void onUserJoined(final String uid, int elapsed) {
            super.onUserJoined(uid, elapsed);
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    logI(uid+"加入频道");

                }
            });
        }



        // SDK 接收到第一帧远端视频并成功解码时，会触发该回调。
        // 可以在该回调中调用 setupRemoteVideo 方法设置远端视图。
        @Override
        public void onFirstRemoteVideoDecoded(String uid, int width, int height, int elapsed) {
            super.onFirstRemoteVideoDecoded(uid, width, height, elapsed);
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    setupRemoteVideo(uid);
                }
            });
        }

        @Override
        public void onUserOffline(final String uid, int reason) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    logI(uid+"离开频道");
                    removeRemoteVideo(uid);
                }
            });
        }

        @Override
        public void onError(int err) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    logI("onError"+err);
                }
            });
        }
    };

    private void setupLocalVideo() {

        //创建TextureView对象
        TextureView mLocalView = RtcEngine.CreateRendererView(getBaseContext());
        if (rlLocal!=null){
            rlLocal.removeAllViews();
        }
        rlLocal.addView(mLocalView);
        //设置本地视图
        mRtcEngine.setupLocalVideo(new VideoCanvas(mLocalView, VideoCanvas.RENDER_MODE_FIT, userId));
    }


    private void setupRemoteVideo(String uid) {
            if (rlRemote!=null){
                rlRemote.removeAllViews();
            }
            remoteId = uid;
            TextureView mRemoteView = RtcEngine.CreateRendererView(getBaseContext());
            rlRemote.addView(mRemoteView);
            mRtcEngine.setupRemoteVideo(new VideoCanvas(mRemoteView, Constants.RENDER_MODE_HIDDEN,"100000", uid, Constants.VIDEO_MIRROR_MODE_DISABLED));
    }


    private void removeRemoteVideo(String uid) {
        if (rlRemote!=null){
            if (remoteId.equals(uid)) {
                rlRemote.removeAllViews();
            }
        }
    }

    private void logI(String log){
        Log.d("VideoActivity",log);
    }
    private void removeLocalVideo() {
        if (rlLocal!=null){
            rlLocal.removeAllViews();
        }
    }
    private void startCall() {
        setupLocalVideo();
        joinChannel();
    }

    private void endCall() {
        removeLocalVideo();
        removeRemoteVideo(remoteId);
        leaveChannel();
    }

    private void showButtons(boolean show) {
        int visibility = show ? View.VISIBLE : View.GONE;
        ivMuteVideo.setVisibility(visibility);
        ivSwitch.setVisibility(visibility);
        ivMuteAudio.setVisibility(visibility);
    }


    @Override
    public void onClick(View v) {
        switch (v.getId()){
            case R.id.btn_audio_mute:
                ivMuteAudio.setSelected(!ivMuteAudio.isSelected());
                mRtcEngine.muteLocalAudioStream(ivMuteAudio.isSelected());
                break;
            case R.id.btn_video_mute:
                ivMuteVideo.setSelected(!ivMuteVideo.isSelected());
                mRtcEngine.muteLocalVideoStream(ivMuteVideo.isSelected());
                break;
            case R.id.btn_call:
                if (mCallEnd) {
                    startCall();
                    mCallEnd = false;
                    ivCall.setImageResource(R.drawable.img_leave);
                } else {
                    endCall();
                    mCallEnd = true;
                    ivCall.setImageResource(R.drawable.img_join);
                }
                showButtons(!mCallEnd);
                break;
            case R.id.btn_switch_camera:
                mRtcEngine.switchCamera();
                break;
        }

    }

    private boolean checkSelfPermission(String permission, int requestCode) {
        if (ContextCompat.checkSelfPermission(this, permission) !=
                PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, REQUESTED_PERMISSIONS, requestCode);
            return false;
        }
        return true;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        if (requestCode == PERMISSION_REQ_ID) {
            if (grantResults[0] != PackageManager.PERMISSION_GRANTED ||
                    grantResults[1] != PackageManager.PERMISSION_GRANTED ||
                    grantResults[2] != PackageManager.PERMISSION_GRANTED) {
                showToast("Need permissions " + Manifest.permission.RECORD_AUDIO +
                        "/" + Manifest.permission.CAMERA + "/" + Manifest.permission.WRITE_EXTERNAL_STORAGE);
                finish();
                return;
            }
            initEngineAndJoinChannel();
        }
    }

    private void showToast(final String msg) {
        this.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(getApplicationContext(), msg, Toast.LENGTH_SHORT).show();
            }
        });
    }


    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode== KeyEvent.KEYCODE_BACK){
            if (!mCallEnd){
                endCall();
                finish();
                return true;
            }

        }
        return super.onKeyDown(keyCode, event);
    }


    @Override
    protected void onDestroy() {
        super.onDestroy();
        videoRawData.unsubscribe();
        RtcEngine.destroy();
    }

    @Override
    public void onCaptureVideoFrame(@NotNull Bitmap bitmap) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {//原始视频数据 转成图片
                iv_bitmap.setImageBitmap(bitmap);
            }
        });

    }
}