#!/bin/sh

# 기존 파일 정리
rm -f cscope.files cscope.out cscope.in.out cscope.po.out tags

# 1. compile_commands.json 파일 존재 여부 확인
if [ ! -f compile_commands.json ]; then
    echo "Error: compile_commands.json file not found."
    exit 1
fi

echo "Found compile_commands.json. Generating tags for built files only..."

# jq를 사용하여 compile_commands.json에서 파일 경로를 추출
# 상대 경로인 경우 directory 필드와 결합하여 절대 경로로 변환하여 저장
jq -r '.[] | if (.file | startswith("/")) then .file else (.directory + "/" + .file) end' compile_commands.json 2>/dev/null | sort -u > cscope.files

if [ $? -ne 0 ] || [ ! -s cscope.files ]; then
    echo "Error: Failed to parse compile_commands.json with jq."
    exit 1
fi

# 방법 A: 빌드 시 생성된 의존성(.cmd) 파일들로부터 .h 파일 경로를 추출하여 추가
echo "Extracting referenced header files from build dependency files (*.cmd)..."
find . -name "*.cmd" -exec grep -h -o '[^ ]*\.h' {} + 2>/dev/null | \
    sed -e 's/[<>"'\''\\]//g' -e 's/^savedcmd_//' | \
    sort -u | \
    while read -r file; do
        # 실제로 존재하는 파일만 필터링하여 노이즈 제거
        if [ -f "$file" ]; then
            echo "$file"
        fi
    done >> cscope.files

# 커널인 경우(해당 파일들이 존재할 때만) CONFIG 관련 자동 생성 헤더 강제 추가
for conf_file in "include/linux/kconfig.h" "include/generated/autoconf.h"; do
    if [ -f "$conf_file" ]; then
        echo "Adding CONFIG header: $conf_file"
        echo "$conf_file" >> cscope.files
    fi
done

# 중복 경로 제거 및 정렬
sort -u cscope.files -o cscope.files

# cscope 및 ctags 생성
if [ -s cscope.files ]; then
    echo "Building cscope database..."
    cscope -b -q -k -i cscope.files

    echo "Building ctags..."
    ctags -L cscope.files

    echo "Done! cscope and ctags databases generated successfully."
else
    echo "Error: No source files found to tag."
    exit 1
fi
