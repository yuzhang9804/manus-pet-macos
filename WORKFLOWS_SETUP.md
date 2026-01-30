# GitHub Actions 工作流配置指南

由于 GitHub App 权限限制，需要手动添加以下工作流文件到仓库。

## 步骤

1. 访问仓库：https://github.com/yuzhang9804/manus-pet-macos
2. 点击 **Add file** → **Create new file**
3. 按照下面的说明创建 3 个文件

---

## 文件 1: `.github/workflows/build.yml`

**路径**: `.github/workflows/build.yml`

```yaml
name: Build

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-14
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app/Contents/Developer
      
      - name: Show Xcode version
        run: xcodebuild -version
      
      - name: Build
        run: |
          xcodebuild build \
            -project ManusPet.xcodeproj \
            -scheme ManusPet \
            -configuration Debug \
            -destination 'platform=macOS,arch=arm64' \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO
      
      - name: Build Release
        run: |
          xcodebuild build \
            -project ManusPet.xcodeproj \
            -scheme ManusPet \
            -configuration Release \
            -destination 'platform=macOS,arch=arm64' \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO
```

---

## 文件 2: `.github/workflows/auto-tag.yml`

**路径**: `.github/workflows/auto-tag.yml`

```yaml
name: Auto Tag

on:
  push:
    branches: [main]
    paths-ignore:
      - '**.md'
      - '.github/**'

permissions:
  contents: write

jobs:
  tag:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Get latest tag
        id: get_latest_tag
        run: |
          LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
          echo "LATEST_TAG=$LATEST_TAG" >> $GITHUB_OUTPUT
          echo "Latest tag: $LATEST_TAG"
      
      - name: Calculate next version
        id: next_version
        run: |
          LATEST_TAG="${{ steps.get_latest_tag.outputs.LATEST_TAG }}"
          VERSION=${LATEST_TAG#v}
          IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
          COMMIT_MSG=$(git log -1 --pretty=%B)
          
          if echo "$COMMIT_MSG" | grep -qiE "^(feat|feature)(\(.+\))?!:|BREAKING CHANGE"; then
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
          elif echo "$COMMIT_MSG" | grep -qiE "^feat(\(.+\))?:"; then
            MINOR=$((MINOR + 1))
            PATCH=0
          else
            PATCH=$((PATCH + 1))
          fi
          
          NEW_VERSION="v${MAJOR}.${MINOR}.${PATCH}"
          echo "NEW_VERSION=$NEW_VERSION" >> $GITHUB_OUTPUT
          echo "New version: $NEW_VERSION"
      
      - name: Check if tag exists
        id: check_tag
        run: |
          if git rev-parse "${{ steps.next_version.outputs.NEW_VERSION }}" >/dev/null 2>&1; then
            echo "TAG_EXISTS=true" >> $GITHUB_OUTPUT
          else
            echo "TAG_EXISTS=false" >> $GITHUB_OUTPUT
          fi
      
      - name: Create and push tag
        if: steps.check_tag.outputs.TAG_EXISTS == 'false'
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          
          NEW_TAG="${{ steps.next_version.outputs.NEW_VERSION }}"
          git tag -a "$NEW_TAG" -m "Release $NEW_TAG"
          git push origin "$NEW_TAG"
          
          echo "Created and pushed tag: $NEW_TAG"
```

---

## 文件 3: `.github/workflows/release.yml`

**路径**: `.github/workflows/release.yml`

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  build-and-release:
    runs-on: macos-14
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app/Contents/Developer
      
      - name: Show Xcode version
        run: xcodebuild -version
      
      - name: Get version from tag
        id: get_version
        run: echo "VERSION=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT
      
      - name: Update version in project
        run: |
          /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${{ steps.get_version.outputs.VERSION }}" ManusPet/Info.plist
          /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${{ github.run_number }}" ManusPet/Info.plist
      
      - name: Build Release (arm64)
        run: |
          xcodebuild archive \
            -project ManusPet.xcodeproj \
            -scheme ManusPet \
            -configuration Release \
            -destination 'generic/platform=macOS' \
            -archivePath build/ManusPet-arm64.xcarchive \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO \
            ONLY_ACTIVE_ARCH=NO
      
      - name: Export app
        run: |
          mkdir -p build/export
          cp -R build/ManusPet-arm64.xcarchive/Products/Applications/ManusPet.app build/export/
      
      - name: Create DMG
        run: |
          mkdir -p build/dmg-contents
          cp -R build/export/ManusPet.app build/dmg-contents/
          ln -s /Applications build/dmg-contents/Applications
          hdiutil create -volname "Manus Pet" \
            -srcfolder build/dmg-contents \
            -ov -format UDZO \
            build/ManusPet-${{ steps.get_version.outputs.VERSION }}.dmg
      
      - name: Create ZIP
        run: |
          cd build/export
          zip -r ../ManusPet-${{ steps.get_version.outputs.VERSION }}.zip ManusPet.app
      
      - name: Generate changelog
        id: changelog
        run: |
          echo "CHANGELOG<<EOF" >> $GITHUB_OUTPUT
          echo "## What's Changed" >> $GITHUB_OUTPUT
          echo "" >> $GITHUB_OUTPUT
          echo "### Features" >> $GITHUB_OUTPUT
          echo "- Desktop pet with Sprite animation system" >> $GITHUB_OUTPUT
          echo "- Manus API integration for task monitoring" >> $GITHUB_OUTPUT
          echo "- Sprite Gallery for browsing and installing custom sprites" >> $GITHUB_OUTPUT
          echo "- System tray integration" >> $GITHUB_OUTPUT
          echo "" >> $GITHUB_OUTPUT
          echo "### Requirements" >> $GITHUB_OUTPUT
          echo "- macOS 13.0 (Ventura) or later" >> $GITHUB_OUTPUT
          echo "" >> $GITHUB_OUTPUT
          echo "**Full Changelog**: https://github.com/${{ github.repository }}/commits/v${{ steps.get_version.outputs.VERSION }}" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          name: Manus Pet v${{ steps.get_version.outputs.VERSION }}
          body: ${{ steps.changelog.outputs.CHANGELOG }}
          draft: false
          prerelease: false
          files: |
            build/ManusPet-${{ steps.get_version.outputs.VERSION }}.dmg
            build/ManusPet-${{ steps.get_version.outputs.VERSION }}.zip
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 工作流说明

| 工作流 | 触发条件 | 功能 |
|--------|----------|------|
| `build.yml` | 推送到 main 分支或 PR | 编译项目，验证代码正确性 |
| `auto-tag.yml` | 推送到 main 分支（非 .md 文件） | 根据 commit message 自动创建版本 tag |
| `release.yml` | 推送 v* 格式的 tag | 构建应用并发布 Release（DMG + ZIP） |

## 版本号规则

Auto Tag 工作流会根据 commit message 自动决定版本号递增：

- `feat!:` 或 `BREAKING CHANGE` → Major 版本 (x.0.0)
- `feat:` → Minor 版本 (0.x.0)
- 其他 → Patch 版本 (0.0.x)

## 手动发布

如果需要手动发布特定版本，可以直接创建 tag：

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```
