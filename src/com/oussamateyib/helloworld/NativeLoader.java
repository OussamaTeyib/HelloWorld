package com.oussamateyib.helloworld;

public class NativeLoader extends android.app.NativeActivity {
     static {
        System.loadLibrary("hello_world");
     }
}