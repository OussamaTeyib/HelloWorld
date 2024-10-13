rm *.apk *.idsig *.so *.dex *.a
make
aapt package -f -m -S ../res -J ../src -M ../AndroidManifest.xml -I %ANDROID_HOME%/platforms/android-35/android.jar
javac --source 11 --target 11 --system %JAVA_HOME% --class-path %ANDROID_HOME%/platforms/android-35/android.jar --source-path ../src ../src/com/oussamateyib/helloworld/R.java ../src/com/oussamateyib/helloworld/NativeLoader.java
d8 ../src/com/oussamateyib/helloworld/*.class --release --lib %ANDROID_HOME%/platforms/android-35/android.jar
aapt package -f -m -F HelloWorld-temp.apk -M ../AndroidManifest.xml -S ../res -I %ANDROID_HOME%/platforms/android-35/android.jar
aapt add HelloWorld-temp.apk lib/arm64-v8a/libhello_world.so
aapt add HelloWorld-temp.apk classes.dex
zipalign -p -f 4 HelloWorld-temp.apk HelloWorld.apk
apksigner sign --ks my-key.jks --ks-key-alias HelloWorld HelloWorld.apk