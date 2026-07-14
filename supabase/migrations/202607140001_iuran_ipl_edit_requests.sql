create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role::text = 'SUPER_ADMIN'
  );
$$;

grant execute on function public.is_super_admin() to authenticated;

create table if not exists public.iuran_ipl_edit_requests (
  id uuid primary key default gen_random_uuid(),
  iuran_id uuid not null references public.iuran_ipl(id) on delete cascade,
  requested_by uuid not null references public.profiles(id),
  status text not null default 'PENDING'
    check (status in ('PENDING', 'APPROVED', 'REJECTED')),
  original_bulan_bayar int[] not null default '{}',
  original_total_bayar numeric not null default 0,
  original_keterangan text,
  proposed_bulan_bayar int[] not null default '{}',
  proposed_total_bayar numeric not null default 0,
  proposed_keterangan text,
  request_note text,
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  review_note text,
  created_at timestamptz not null default now()
);

alter table public.iuran_ipl_edit_requests enable row level security;

drop policy if exists "ipl_edit_requests_select" on public.iuran_ipl_edit_requests;
drop policy if exists "ipl_edit_requests_insert_admin" on public.iuran_ipl_edit_requests;
drop policy if exists "ipl_edit_requests_review_super_admin" on public.iuran_ipl_edit_requests;

create policy "ipl_edit_requests_select"
on public.iuran_ipl_edit_requests
for select
to authenticated
using (
  public.is_super_admin()
  or requested_by = auth.uid()
);

create policy "ipl_edit_requests_insert_admin"
on public.iuran_ipl_edit_requests
for insert
to authenticated
with check (
  public.is_admin()
  and requested_by = auth.uid()
  and status = 'PENDING'
  and reviewed_by is null
  and reviewed_at is null
);

create policy "ipl_edit_requests_review_super_admin"
on public.iuran_ipl_edit_requests
for update
to authenticated
using (public.is_super_admin())
with check (public.is_super_admin());

create or replace function public.review_iuran_ipl_edit_request(
  p_request_id uuid,
  p_approve boolean,
  p_review_note text default null
)
returns public.iuran_ipl_edit_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request public.iuran_ipl_edit_requests;
  v_reviewer text;
  v_status text;
begin
  if not public.is_super_admin() then
    raise exception 'Only SUPER_ADMIN can review IPL edit requests';
  end if;

  -- Concurrency guard:
  -- `for update` locks the pending request row. If two SUPER_ADMIN users click
  -- approve/reject at the same time, the first transaction changes the status,
  -- and the second transaction finds no remaining PENDING row.
  select *
  into v_request
  from public.iuran_ipl_edit_requests
  where id = p_request_id
    and status = 'PENDING'
  for update;

  if not found then
    raise exception 'Request sudah diproses oleh super admin lain';
  end if;

  select username
  into v_reviewer
  from public.profiles
  where id = auth.uid();

  v_status := case when p_approve then 'APPROVED' else 'REJECTED' end;

  if p_approve then
    update public.iuran_ipl
    set
      bulan_bayar = v_request.proposed_bulan_bayar,
      total_bayar = v_request.proposed_total_bayar,
      keterangan = concat_ws(
        E'\n',
        v_request.proposed_keterangan,
        'Disetujui oleh: ' || coalesce(v_reviewer, auth.uid()::text) ||
          ' (SUPER_ADMIN) pada ' || to_char(now(), 'YYYY-MM-DD HH24:MI:SS TZ')
      )
    where id = v_request.iuran_id;
  end if;

  update public.iuran_ipl_edit_requests
  set
    status = v_status,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_note = p_review_note
  where id = p_request_id
  returning * into v_request;

  return v_request;
end;
$$;

grant execute on function public.review_iuran_ipl_edit_request(uuid, boolean, text)
to authenticated;
