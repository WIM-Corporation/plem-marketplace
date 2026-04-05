---
name: register-plugin
description: "Use when adding a new skill zip to the marketplace or updating an existing plugin with a new zip. Handles extraction, directory restructuring, manifest creation, marketplace registration, README updates, and validation."
argument-hint: "<zip-file> [--update]"
---

# register-plugin: Skill Zip → Marketplace Plugin

zip 파일로 전달받은 스킬을 plem-marketplace 플러그인으로 등록하거나 업데이트한다.

## Inputs

- `$ARGUMENTS`에서 zip 파일 경로 파싱. 없으면 워킹 디렉토리의 `.zip` 파일 탐색
- `--update` 플래그 또는 `plugins/` 아래 동일 이름 디렉토리 존재 시 업데이트 모드

## Mode Detection

```
if plugins/<name>/ 존재 → UPDATE mode
else → NEW mode
```

---

## NEW Mode — 신규 등록

### Step 1: Extract & Inspect

1. zip 내용 확인 (`unzip -l`)
2. `/tmp/plem-staging/`에 추출
3. SKILL.md frontmatter에서 `name`, `description` 파싱
4. 불필요 파일 제거: `.omc/`, `__pycache__/`, `.DS_Store`, `node_modules/`

### Step 2: Restructure

zip 루트 구조를 플러그인 컨벤션으로 재배치:

```
# zip 내부 (flat)          → 플러그인 구조
<name>/SKILL.md            → plugins/<name>/skills/<name>/SKILL.md
<name>/references/         → plugins/<name>/skills/<name>/references/
<name>/scripts/            → plugins/<name>/skills/<name>/scripts/
```

**핵심**: SKILL.md와 references/scripts는 반드시 `skills/<name>/` 아래에 함께 위치해야 상대경로가 유지된다.

### Step 3: Create plugin.json

`plugins/<name>/.claude-plugin/plugin.json` 생성:

```json
{
  "name": "<name>",
  "description": "<SKILL.md frontmatter description을 한국어로 요약>",
  "version": "1.0.0",
  "keywords": ["<relevant>", "<keywords>"]
}
```

### Step 4: Register in marketplace.json

`.claude-plugin/marketplace.json`의 `plugins` 배열에 추가:

```json
{
  "name": "<name>",
  "source": "./plugins/<name>",
  "description": "<한국어 간단 설명>",
  "version": "1.0.0"
}
```

### Step 5: Update READMEs

두 파일 모두 플러그인 테이블에 행 추가:

- `README.md`: `| [<name>](plugins/<name>) | 1.0.0 | <English description> |`
- `docs/README.ko.md`: `| [<name>](../plugins/<name>) | 1.0.0 | <한국어 설명> |`

### Step 6: Validate & Cleanup

```bash
claude plugin validate .
rm -rf /tmp/plem-staging
```

---

## UPDATE Mode — 기존 플러그인 업데이트

### Step 1: Replace skill content

```bash
rm -rf plugins/<name>/skills/<name>
```

### Step 2: Extract & Copy

1. `/tmp/plem-staging/`에 추출
2. 불필요 파일 제거
3. `plugins/<name>/skills/<name>/`로 재배치 (NEW Mode Step 2와 동일)

### Step 3: Check for structural changes

- 새 reference 파일이 추가되었는지 diff 확인
- SKILL.md frontmatter의 description이 변경되었으면 `plugin.json`, `marketplace.json`, README 반영 여부 확인

### Step 4: Validate & Cleanup

```bash
claude plugin validate .
rm -rf /tmp/plem-staging
```

---

## Success Criteria

- [ ] `claude plugin validate .` 통과
- [ ] `plugins/<name>/skills/<name>/SKILL.md` 존재
- [ ] `marketplace.json` plugins 배열에 항목 존재
- [ ] `README.md`, `docs/README.ko.md` 테이블에 행 존재
- [ ] staging 디렉토리 정리 완료

## Constraints

- zip 내 `.omc/`, `__pycache__/`, `.DS_Store` 등 로컬 상태 파일은 반드시 제거
- `*.zip`은 `.gitignore`에 등록되어 있으므로 커밋 대상 아님
- plugin name은 kebab-case만 허용
- `../` 경로 사용 불가 (보안)
- 버전은 `plugin.json`에서만 관리 (상대경로 플러그인 규칙)
