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
    escaped_var=$(printf '%s\n' "$escaped_var" | sed 's/\[/\\[/g' | sed 's/\]/\\]/g' | sed 's/\./\\./g' | sed 's/;/\\;/g' | sed 's/\$/\\$/g')
    echo $escaped_var
}

patch_method() {
    local file=$1
    local method_name=$2
    local new_body=$3
    local method_line=$(expressions_fix "$(grep " ${method_name}(" $file)")

    if [[ -n "$method_line" ]]; then
        sed -i "/^${method_line}/,/^\.end method/d" $file
        echo "$new_body" >> $file
        echo " - ${method_name} [✓]"
    else
        echo " - ${method_name} [✗]"
    fi
}

check_smali() {
    local file=$1
    local name=$2
    local method_count=$(grep -c "^\.method" $file)
    local end_count=$(grep -c "^\.end method" $file)

    if [ "$method_count" != "$end_count" ]; then
        echo "⚠️ ${name}: Malformed methods detected! (.method: $method_count, .end method: $end_count)"
    else
        echo "✅ ${name}: OK ($method_count methods)"
    fi
}

check_dex_duplicates() {
    echo "Checking for duplicate dex files..."
    local found_dup=false
    declare -A size_map

    while IFS= read -r line; do
        size=$(echo "$line" | awk '{print $1}')
        file=$(echo "$line" | awk '{print $2}')
        if [[ -n "${size_map[$size]}" ]]; then
            if [ "$found_dup" = false ]; then
                echo "⚠️ Duplicate dex detected:"
                found_dup=true
            fi
            echo " - ${size_map[$size]} == $file ($size bytes)"
        else
            size_map[$size]=$file
        fi
    done < <(find tmp_jar/ -name 'classes*.dex' -exec du -b {} \; | sort -k1)

    if [ "$found_dup" = false ]; then
        echo "✅ No duplicate dex files found"
    fi
}

patchservices() {
    jarname=$1

    echo "Decompiling ${jarname}..."
    apkeditor d -i $jarname -o tmp_jar > /dev/null 2>&1
    mv $jarname tmp.jar

    echo ""
    echo "Patching ${jarname}..."
    echo ""

    # Patch FaceService.smali
    local faceServiceclassfile=$(find tmp_jar/ -name 'FaceService.smali' -printf '%P\n' | head -1)
    echo "FaceService:"
    if [[ -f "tmp_jar/$faceServiceclassfile" ]]; then
        patch_method "tmp_jar/$faceServiceclassfile" "getDeclaredInstances" "$faceService_getDeclaredInstances"
    else
        echo " - getDeclaredInstances [✗] (FaceService.smali not found)"
    fi

    echo ""

    # Patch FaceProvider.smali - prefer aidl path
    local faceProviderclassfile=$(find tmp_jar/ -path '*/aidl/FaceProvider.smali' -printf '%P\n' | head -1)
    if [[ -z "$faceProviderclassfile" ]]; then
        faceProviderclassfile=$(find tmp_jar/ -name 'FaceProvider.smali' -printf '%P\n' | head -1)
    fi

    echo "FaceProvider:"
    if [[ -f "tmp_jar/$faceProviderclassfile" ]]; then
        patch_method "tmp_jar/$faceProviderclassfile" "initSensors" "$faceProvider_initSensors"
        patch_method "tmp_jar/$faceProviderclassfile" "cancelAuthentication" "$cancelAuth"
        patch_method "tmp_jar/$faceProviderclassfile" "cancelEnrollment" "$cancelEnroll"
        patch_method "tmp_jar/$faceProviderclassfile" "getAuthenticatorId" "$getAuthID"
        patch_method "tmp_jar/$faceProviderclassfile" "getEnrolledFaces" "$getEnrolledF"
        patch_method "tmp_jar/$faceProviderclassfile" "isHardwareDetected" "$isHwDetected"
        patch_method "tmp_jar/$faceProviderclassfile" "scheduleAuthenticate" "$schedAuth"
        patch_method "tmp_jar/$faceProviderclassfile" "scheduleEnroll" "$schedEnroll"
        patch_method "tmp_jar/$faceProviderclassfile" "scheduleGenerateChallenge" "$schedGenClg"
        patch_method "tmp_jar/$faceProviderclassfile" "scheduleRemove" "$schedRM"
        patch_method "tmp_jar/$faceProviderclassfile" "scheduleRevokeChallenge" "$schedRevClg"
        patch_method "tmp_jar/$faceProviderclassfile" 'lambda$new$2' "$faceProvider_lambda"
    else
        echo " - (FaceProvider.smali not found)"
    fi

    echo ""

    # Optional: Disable Secure Screenshot
    echo "Disable Secure Screenshot:"
    if [[ "$DISABLE_SECURE_SCREENSHOT" == "true" ]]; then
        local wmsclassfile=$(find tmp_jar/ -name 'WindowManagerService.smali' -printf '%P\n' | head -1)
        if [[ -f "tmp_jar/$wmsclassfile" ]]; then
            patch_method "tmp_jar/$wmsclassfile" "notifyScreenshotListeners" "$notifyScreenshotListeners"
        else
            echo " - notifyScreenshotListeners [✗] (WindowManagerService.smali not found)"
        fi

        local wsclassfile=$(find tmp_jar/ -name 'WindowState.smali' -printf '%P\n' | head -1)
        if [[ -f "tmp_jar/$wsclassfile" ]]; then
            patch_method "tmp_jar/$wsclassfile" "isSecureLocked" "$isSecureLocked"
        else
            echo " - isSecureLocked [✗] (WindowState.smali not found)"
        fi
    else
        echo " - Skipped"
    fi

    echo ""

    # Check smali integrity
    echo "Checking smali integrity..."
    [[ -f "tmp_jar/$faceServiceclassfile" ]] && check_smali "tmp_jar/$faceServiceclassfile" "FaceService"
    [[ -f "tmp_jar/$faceProviderclassfile" ]] && check_smali "tmp_jar/$faceProviderclassfile" "FaceProvider"
    if [[ "$DISABLE_SECURE_SCREENSHOT" == "true" ]]; then
        [[ -f "tmp_jar/$wmsclassfile" ]] && check_smali "tmp_jar/$wmsclassfile" "WindowManagerService"
        [[ -f "tmp_jar/$wsclassfile" ]] && check_smali "tmp_jar/$wsclassfile" "WindowState"
    fi

    echo ""
    echo "Compiling ${jarname}..."
    apkeditor b -i tmp_jar > /dev/null 2>&1
    unzip tmp_jar_out.apk 'classes*.dex' -d tmp_jar > /dev/null 2>&1

    rm -rf tmp_jar/.cache

    # Inject classes5.dex
    cp $dirnow/AUTOPATCH/faceunlock/classes.dex tmp_jar/classes5.dex

    echo ""
    check_dex_duplicates

    echo ""
    cd tmp_jar
    echo "Zipping classes..."
    zip -qr0 -t 07302003 $dirnow/tmp.jar classes*
    cd $dirnow

    echo "Zipaligning ${jarname}..."
    zipalign -v 4 tmp.jar $jarname > /dev/null

    rm -rf tmp.jar tmp_jar tmp_jar_out.apk
    echo ""
    echo "✅ Done! Output: ${jarname}"
}

patchservices services.jar
