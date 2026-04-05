# marketplace.json 스키마 및 플러그인 소스 규칙

이 리포지토리는 Claude Code 플러그인 마켓플레이스이다.
카탈로그: `.claude-plugin/marketplace.json`

## marketplace.json 필수 필드

```json
{
  "name": "marketplace-name",
  "owner": { "name": "팀 이름" },
  "plugins": []
}
```

- `name`: kebab-case, 공백 불가
- `owner.name`: 필수. `owner.email`: 선택

## 선택 메타데이터

`description`은 반드시 `metadata` 아래에 배치한다 (루트 레벨 아님):

```json
{
  "metadata": {
    "description": "마켓플레이스 설명",
    "version": "1.0.0",
    "pluginRoot": "./plugins"
  }
}
```

## 플러그인 항목

필수: `name` (kebab-case), `source` (string 또는 object)

선택: `description`, `version`, `author`, `homepage`, `repository`, `license`, `keywords`, `category`, `tags`, `strict`, `commands`, `agents`, `hooks`, `mcpServers`, `lspServers`

## 플러그인 소스 타입

### 상대 경로 (모노레포, 이 리포의 기본 방식)

```json
{ "source": "./plugins/my-plugin" }
```

- `./`로 시작. `../` 불가
- Git 기반 마켓플레이스에서만 동작 (URL 직접 참조 시 미동작)

### GitHub

```json
{ "source": { "source": "github", "repo": "org/plugin-repo", "ref": "v2.0.0", "sha": "a1b2c3d4..." } }
```

- `repo` 필수, `ref`/`sha` 선택

### Git URL

```json
{ "source": { "source": "url", "url": "https://gitlab.com/team/plugin.git", "ref": "main" } }
```

- **`"source": "url"`을 사용한다. `"source": "git"`은 올바르지 않다.**
- npm(`"source": "npm"`), pip(`"source": "pip"`), git-subdir(`"source": "git-subdir"`)도 지원. 상세 스키마는 공식 문서 참조.
- **`"source": "file"` 타입은 존재하지 않는다.**

## 버전 관리

상세 정책은 `versioning.md` 참조.

- 상대 경로 플러그인: `plugin.json`이 런타임 권한. `marketplace.json`에도 동일 버전을 반드시 동기화
- 외부 소스 플러그인: `plugin.json`에서만 version 설정 (marketplace.json 버전은 무시됨)
- Semantic Versioning 2.0.0 준수: MAJOR.MINOR.PATCH

## strict 모드

`marketplace.json` 플러그인 항목의 `strict` 필드:

- `true` (기본): `plugin.json`이 컴포넌트 권한. 마켓플레이스는 보충만 가능
- `false`: 마켓플레이스 항목이 전체 정의. plugin.json에 컴포넌트 선언이 있으면 충돌 → 로드 실패

## 팀 자동 배포 (settings.json)

프로젝트 `.claude/settings.json`에 설정하면 팀원이 리포 trust 시 자동 프롬프트:

```json
{
  "extraKnownMarketplaces": {
    "marketplace-name": {
      "source": { "source": "github", "repo": "WIM-Corporation/plem-marketplace" }
    }
  },
  "enabledPlugins": {
    "plugin-name@marketplace-name": true
  }
}
```
