# Supabase 백엔드 설정

My Raum 2.0은 스캔한 공간을 Supabase에 저장한다 (PRD §9 D-06).
이 문서는 **저장소 코드가 이미 준비된 상태에서, 실제 Supabase 프로젝트를 연결하는 절차**를 정리한 것이다.

> 아래 1~4단계는 Supabase / Apple Developer 계정 권한이 필요하므로 직접 수행해야 한다.

---

## 1. 프로젝트 생성

1. https://supabase.com/dashboard 에서 새 프로젝트를 만든다.
2. **Project Settings → API** 에서 다음 두 값을 복사해 둔다.
   - `Project URL` (예: `https://abcdefgh.supabase.co`)
   - `anon public` 키

> `service_role` 키는 앱에 절대 넣지 않는다. 클라이언트에는 `anon` 키만 사용한다.

---

## 2. 스키마 · RLS · Storage 적용

**SQL Editor** 를 열고 [`supabase/migrations/0001_spaces.sql`](../supabase/migrations/0001_spaces.sql) 전체를 붙여 넣어 실행한다.

한 번에 아래가 모두 만들어진다.

| 항목 | 내용 |
|---|---|
| `public.spaces` 테이블 | 메타데이터 (comment, created_at, lat/lng, furniture, area, structure_id, is_public, storage_path …) |
| RLS 정책 | insert/update/delete 는 본인 row 만, select 는 `owner = auth.uid() OR is_public = true` |
| `space-models` 버킷 | USDZ + 썸네일. 비공개 버킷 |
| Storage 정책 | 경로 첫 세그먼트(`{user_id}/…`)로 소유자 판단, 공개 공간의 파일은 열람 허용 |
| `delete_current_user()` | 계정 삭제용 `security definer` 함수 |

실행 후 **Table Editor → spaces** 와 **Storage → space-models** 가 보이면 정상이다.

---

## 3. Sign in with Apple 연동

### 3-1. Apple Developer

1. **Certificates, Identifiers & Profiles → Identifiers** 에서 App ID `io.github.picturehouse.MyRaum` 를 열고 **Sign In with Apple** 을 켠다.
2. **Keys** 에서 *Sign in with Apple* 용 키를 새로 만들고 `.p8` 파일과 **Key ID** 를 받아 둔다.
3. **Membership** 에서 **Team ID** 를 확인한다.

### 3-2. Supabase

**Authentication → Providers → Apple** 을 켜고 입력한다.

| 필드 | 값 |
|---|---|
| Client IDs | `io.github.picturehouse.MyRaum` (앱 번들 ID) |
| Secret Key (for OAuth) | `.p8` 파일 내용 |
| Key ID | 3-1에서 받은 Key ID |
| Team ID | 3-1에서 확인한 Team ID |

> 네이티브 Sign in with Apple(이 앱이 쓰는 방식)은 `signInWithIdToken` 으로 동작하므로 **Client IDs 에 번들 ID가 들어가 있는 것이 핵심**이다. Redirect URL 설정은 웹 OAuth 흐름에서만 쓰인다.

---

## 4. 앱에 접속 정보 넣기

저장소 루트의 [`Supabase-Info.example.plist`](../Supabase-Info.example.plist) 를 복사해서
**`MyRaum/App/Supabase-Info.plist`** 로 저장하고 1단계에서 복사한 값을 채운다.

```bash
cp Supabase-Info.example.plist MyRaum/App/Supabase-Info.plist
```

```xml
<key>SupabaseURL</key>
<string>https://abcdefgh.supabase.co</string>
<key>SupabaseAnonKey</key>
<string>eyJhbGciOi...</string>
```

- `MyRaum/App/` 은 file-system synchronized group이라 **파일을 두기만 하면 자동으로 앱 번들에 포함된다.**
- 이 경로는 `.gitignore` 에 등록되어 있어 커밋되지 않는다.

### 파일이 없을 때의 동작

앱은 크래시하지 않는다. `SupabaseConfig.loadFromBundle()` 이 `nil` 을 돌려주고,

- 로그인 시도 시 "서버 설정이 없어 로그인할 수 없습니다." 를 표시하고
- `SyncQueue` 는 업로드를 시도하지 않으며 공간은 `pending` 상태로 남는다.

즉 **설정 전에도 빌드·실행은 되지만 로그인이 필요한 기능은 사용할 수 없다.**

---

## 5. 확인

1. 앱을 실기기에서 실행 → 온보딩 → **Apple로 로그인**
2. Supabase **Authentication → Users** 에 사용자가 생기는지 확인
3. 공간을 스캔하고 저장 → 카드 상세의 동기화 상태가 `업로드 대기 중` → `업로드 완료` 로 바뀌는지 확인
4. **Table Editor → spaces** 에 행이 생기고 **Storage → space-models/{user_id}/** 에 `.usdz` 와 `.png` 가 올라갔는지 확인
5. 앱 삭제 후 재설치 → 로그인 → 공간이 자동으로 복원되는지 확인 (6B.7)

---

## 남은 항목 (코드 밖 작업)

- [ ] **App Store 개인정보 라벨** — 데이터 수집에 **위치** 추가. 모든 신규 공간의 좌표가 서버에 저장된다
- [ ] **개인정보 처리방침** 갱신 — 서버 저장, 공개 설정 시 위치 노출, 계정 삭제 방법
- [ ] **릴리즈 노트** — iOS 18 미만에서는 2.0으로 업데이트할 수 없다는 점 명시 (D-01)

> `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` 의 "위치 데이터는 사용자만이 볼 수 있습니다" 문구는 더 이상 사실이 아니므로 Phase 6에서 이미 갱신했다.
