-- My Raum 2.0 — spaces 테이블 · Storage 버킷 · RLS 정책
-- Supabase 대시보드의 SQL Editor에 그대로 붙여 넣어 실행한다.
-- PRD 6B.3 / 6B.4 / 6B.5 대응.

-- ---------------------------------------------------------------------------
-- 1. spaces 테이블 (6B.4)
-- ---------------------------------------------------------------------------
create table if not exists public.spaces (
    id                uuid primary key,
    owner             uuid not null references auth.users (id) on delete cascade,
    comment           text not null default '',
    created_at        timestamptz not null default now(),
    latitude          double precision not null default 0,
    longitude         double precision not null default 0,

    -- Storage 버킷 안의 경로
    storage_path      text,
    thumbnail_path    text,

    -- RoomPlan 파생 데이터
    furniture         text,
    floor_area_sq_m   double precision,
    room_type_guess   text,

    -- MultiRoom (D-04)
    structure_id      uuid,
    structure_order   integer,

    -- 카드 표시 옵션
    shows_date        boolean not null default true,

    -- 공개 여부. 업로드 여부가 아니라 타인 공개 여부만 제어한다 (D-06)
    is_public         boolean not null default false,

    updated_at        timestamptz not null default now()
);

create index if not exists spaces_owner_idx on public.spaces (owner);
create index if not exists spaces_public_idx on public.spaces (is_public) where is_public;
create index if not exists spaces_structure_idx on public.spaces (structure_id);

-- updated_at 자동 갱신
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists spaces_touch_updated_at on public.spaces;
create trigger spaces_touch_updated_at
    before update on public.spaces
    for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- 2. RLS 정책 (6B.5)
--    insert/update/delete 는 본인 row 만.
--    select 는 owner = auth.uid() OR is_public = true.
-- ---------------------------------------------------------------------------
alter table public.spaces enable row level security;

drop policy if exists "spaces_select_own_or_public" on public.spaces;
create policy "spaces_select_own_or_public"
    on public.spaces for select
    using (owner = (select auth.uid()) or is_public = true);

drop policy if exists "spaces_insert_own" on public.spaces;
create policy "spaces_insert_own"
    on public.spaces for insert
    with check (owner = (select auth.uid()));

drop policy if exists "spaces_update_own" on public.spaces;
create policy "spaces_update_own"
    on public.spaces for update
    using (owner = (select auth.uid()))
    with check (owner = (select auth.uid()));

drop policy if exists "spaces_delete_own" on public.spaces;
create policy "spaces_delete_own"
    on public.spaces for delete
    using (owner = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- 3. Storage 버킷 space-models (6B.3)
--    파일 경로 규칙: {user_id}/{space_id}.usdz , {user_id}/{space_id}.png
--    경로 첫 번째 세그먼트가 소유자 id 이므로 그것으로 권한을 판단한다.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('space-models', 'space-models', false)
on conflict (id) do nothing;

drop policy if exists "space_models_insert_own" on storage.objects;
create policy "space_models_insert_own"
    on storage.objects for insert
    with check (
        bucket_id = 'space-models'
        and (storage.foldername(name))[1] = (select auth.uid())::text
    );

drop policy if exists "space_models_update_own" on storage.objects;
create policy "space_models_update_own"
    on storage.objects for update
    using (
        bucket_id = 'space-models'
        and (storage.foldername(name))[1] = (select auth.uid())::text
    );

drop policy if exists "space_models_delete_own" on storage.objects;
create policy "space_models_delete_own"
    on storage.objects for delete
    using (
        bucket_id = 'space-models'
        and (storage.foldername(name))[1] = (select auth.uid())::text
    );

-- 본인 파일이거나, 공개로 설정된 공간에 연결된 파일이면 읽을 수 있다.
drop policy if exists "space_models_select_own_or_public" on storage.objects;
create policy "space_models_select_own_or_public"
    on storage.objects for select
    using (
        bucket_id = 'space-models'
        and (
            (storage.foldername(name))[1] = (select auth.uid())::text
            or exists (
                select 1 from public.spaces s
                where s.is_public = true
                  and (s.storage_path = storage.objects.name or s.thumbnail_path = storage.objects.name)
            )
        )
    );

-- ---------------------------------------------------------------------------
-- 4. 계정 삭제 (6A.6)
--    클라이언트 권한으로는 auth.users 를 지울 수 없으므로 security definer 함수를 둔다.
--    spaces 는 on delete cascade 로 함께 지워지고, Storage 파일은 아래에서 지운다.
-- ---------------------------------------------------------------------------
create or replace function public.delete_current_user()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    uid uuid := auth.uid();
begin
    if uid is null then
        raise exception 'not authenticated';
    end if;

    delete from storage.objects
     where bucket_id = 'space-models'
       and (storage.foldername(name))[1] = uid::text;

    delete from public.spaces where owner = uid;
    delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_current_user() from public;
grant execute on function public.delete_current_user() to authenticated;
