#!/bin/bash
dirnow=$PWD
source $dirnow/AUTOPATCH/faceunlock/patch

apkeditor() {
    jarfile=$dirnow/AUTOPATCH/tool/APKEditor.jar
    javaOpts="-Xmx6056M -Dfile.encoding=utf-8 -Djdk.util.zip.disableZip64ExtraFieldValidation=true -Djdk.nio.zipfs.allowDotZipEntry=true"
    java $javaOpts -jar "$jarfile" "$@"
}

expressions_fix() {
    var=$1
    escaped_var=$(printf '%s\n' "$var" | sed 's/[\/&]/\\&/g')
    escaped_var=$(printf '%s\n' "$escaped_var" | sed 's/\[/\\[/g' | sed 's/\]/\\]/g' | sed 's/\./\\./g' | sed 's/;/\\;/g')
    echo $escaped_var
}

patchservices() {
    jarname=$1

    echo "Decompiling ${jarname}..."
    apkeditor d -i $jarname -o tmp_jar > /dev/null 2>&1
    mv $jarname tmp.jar

    echo "Patching ${jarname}..."

    # Patch FaceService.smali
    local faceServiceclassfile=$(find tmp_jar/ -name 'FaceService.smali' -printf '%P\n' | head -1)
    if [[ -f "tmp_jar/$faceServiceclassfile" ]]; then
        echo "Patching FaceService..."
        local getDeclaredInstMethod=$(expressions_fix "$(grep ' getDeclaredInstances(' tmp_jar/$faceServiceclassfile)")
        sed -i "/^${getDeclaredInstMethod}/,/^\.end method/d" tmp_jar/$faceServiceclassfile
        echo "$faceService_getDeclaredInstances" >> tmp_jar/$faceServiceclassfile
        echo "✅ FaceService patched"
    else
        echo "⚠️ FaceService.smali not found!"
    fi

    # Patch FaceProvider.smali - prefer aidl path
    local faceProviderclassfile=$(find tmp_jar/ -path '*/aidl/FaceProvider.smali' -printf '%P\n' | head -1)
    if [[ -z "$faceProviderclassfile" ]]; then
        faceProviderclassfile=$(find tmp_jar/ -name 'FaceProvider.smali' -printf '%P\n' | head -1)
    fi

    if [[ -f "tmp_jar/$faceProviderclassfile" ]]; then
        echo "Patching FaceProvider methods..."

        local initSensMethod=$(expressions_fix "$(grep ' initSensors(' tmp_jar/$faceProviderclassfile)")
        local lambdaMethod=$(expressions_fix "$(grep ' lambda\$new\$2(' tmp_jar/$faceProviderclassfile)")
        local cancelAuthMethod=$(expressions_fix "$(grep ' cancelAuthentication(' tmp_jar/$faceProviderclassfile)")
        local cancelEnrollMethod=$(expressions_fix "$(grep ' cancelEnrollment(' tmp_jar/$faceProviderclassfile)")
        local getAuthIDMethod=$(expressions_fix "$(grep ' getAuthenticatorId(' tmp_jar/$faceProviderclassfile)")
        local getEnrolledFMethod=$(expressions_fix "$(grep ' getEnrolledFaces(' tmp_jar/$faceProviderclassfile)")
        local isHwDetectMethod=$(expressions_fix "$(grep ' isHardwareDetected(' tmp_jar/$faceProviderclassfile)")
        local schedAuthMethod=$(expressions_fix "$(grep ' scheduleAuthenticate(' tmp_jar/$faceProviderclassfile)")
        local schedEnrollMethod=$(expressions_fix "$(grep ' scheduleEnroll(' tmp_jar/$faceProviderclassfile)")
        local schedGenClgMethod=$(expressions_fix "$(grep ' scheduleGenerateChallenge(' tmp_jar/$faceProviderclassfile)")
        local schedRMMethod=$(expressions_fix "$(grep ' scheduleRemove(' tmp_jar/$faceProviderclassfile)")
        local schedRevClgMethod=$(expressions_fix "$(grep ' scheduleRevokeChallenge(' tmp_jar/$faceProviderclassfile)")

        sed -i "/^${initSensMethod}/,/^\.end method/d" tmp_jar/$faceProviderclassfile
        sed -i "/^${lambdaMethod}/,/^\.end method/d" tmp_jar/$faceProviderclassfile
        sed -i "/^${cancelAuthMethod}/,/^\.end method/d" tmp_jar/$faceProviderclassfile
        sed -i "/^${cancelEnrollMethod}/,/^\.end method/d" tmp_jar/$faceProviderclassfile
        if [[ -n "$getAuthIDMethod" ]]; then
            sed -i "/^${getAuthIDMethod}/,/^\.end method/d" tmp_jar/$faceProviderclassfile
        else
            echo "⚠️ getAuthenticatorId not found, skipping"
        fi
        sed -i "/^${getEnrolledFMethod}/,/^\.end method/d" tmp_jar/$faceProviderclassfile
        sed -i "/^${isHwDetectMethod}/,/^\.end method/d" tmp_jar/$faceProviderclassfile
        sed -i "/^${schedAuthMethod}/,/^\.end method/d" tmp_jar/$faceProviderclassfile
        sed -i "/^${schedEnrollMethod}/,/^\.end method/d" tmp_jar/$faceProviderclassfile
        sed -i "/^${schedGenClgMethod}/,/^\.end method/d" tmp_jar/$faceProviderclassfile
        sed -i "/^${schedRMMethod}/,/^\.end method/d" tmp_jar/$faceProviderclassfile
        sed -i "/^${schedRevClgMethod}/,/^\.end method/d" tmp_jar/$faceProviderclassfile

        echo "$faceProvider_initSensors" >> tmp_jar/$faceProviderclassfile
        echo "$faceProvider_lambda" >> tmp_jar/$faceProviderclassfile
        echo "$cancelAuth" >> tmp_jar/$faceProviderclassfile
        echo "$cancelEnroll" >> tmp_jar/$faceProviderclassfile
        echo "$getAuthID" >> tmp_jar/$faceProviderclassfile
        echo "$getEnrolledF" >> tmp_jar/$faceProviderclassfile
        echo "$isHwDetected" >> tmp_jar/$faceProviderclassfile
        echo "$schedAuth" >> tmp_jar/$faceProviderclassfile
        echo "$schedEnroll" >> tmp_jar/$faceProviderclassfile
        echo "$schedGenClg" >> tmp_jar/$faceProviderclassfile
        echo "$schedRM" >> tmp_jar/$faceProviderclassfile
        echo "$schedRevClg" >> tmp_jar/$faceProviderclassfile

        echo "✅ FaceProvider patched"
    else
        echo "⚠️ FaceProvider.smali not found!"
    fi

    # Optional: Disable Secure Screenshot
    if [[ "$DISABLE_SECURE_SCREENSHOT" == "true" ]]; then
        echo "📸 Patching Disable Secure Screenshot..."

        local wmsclassfile=$(find tmp_jar/ -name 'WindowManagerService.smali' -printf '%P\n' | head -1)
        if [[ -f "tmp_jar/$wmsclassfile" ]]; then
            local notifyMethod=$(expressions_fix "$(grep ' notifyScreenshotListeners(' tmp_jar/$wmsclassfile)")
            sed -i "/^${notifyMethod}/,/^\.end method/d" tmp_jar/$wmsclassfile
            echo "$notifyScreenshotListeners" >> tmp_jar/$wmsclassfile
            echo "✅ WindowManagerService patched"
        else
            echo "⚠️ WindowManagerService.smali not found!"
        fi

        local wsclassfile=$(find tmp_jar/ -name 'WindowState.smali' -printf '%P\n' | head -1)
        if [[ -f "tmp_jar/$wsclassfile" ]]; then
            local isSecureMethod=$(expressions_fix "$(grep ' isSecureLocked(' tmp_jar/$wsclassfile)")
            sed -i "/^${isSecureMethod}/,/^\.end method/d" tmp_jar/$wsclassfile
            echo "$isSecureLocked" >> tmp_jar/$wsclassfile
            echo "✅ WindowState patched"
        else
            echo "⚠️ WindowState.smali not found!"
        fi
    else
        echo "⏭️ Skipping Disable Secure Screenshot"
    fi

    echo "Compiling ${jarname}..."
    apkeditor b -i tmp_jar > /dev/null 2>&1
    unzip tmp_jar_out.apk 'classes*.dex' -d tmp_jar > /dev/null 2>&1

    rm -rf tmp_jar/.cache
    local patchclass=$(expr $(find tmp_jar/ -type f -name '*.dex' | wc -l) + 1)
    cp $dirnow/AUTOPATCH/faceunlock/classes.dex tmp_jar/classes${patchclass}.dex

    cd tmp_jar
    echo "Zipping classes..."
    zip -qr0 -t 07302003 $dirnow/tmp.jar classes*
    cd $dirnow

    echo "Zipaligning ${jarname}..."
    zipalign -v 4 tmp.jar $jarname > /dev/null

    rm -rf tmp.jar tmp_jar tmp_jar_out.apk
    echo "✅ Done! Output: ${jarname}"
}

patchservices services.jar
