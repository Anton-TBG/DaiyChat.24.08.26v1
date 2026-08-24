/*
# Fix Security Advisor Warnings

## Overview
Addresses three security advisor findings on the existing schema:
1. `update_updated_at_column()` has a mutable search_path (WARN).
2. `handle_new_user()` SECURITY DEFINER function is callable by `anon` (WARN).
3. `handle_new_user()` SECURITY DEFINER function is callable by `authenticated` (WARN).

## Changes
1. Recreate `update_updated_at_column()` with an explicit `search_path = public`
   so the search path cannot be hijacked by an attacker-controlled schema.
2. Revoke EXECUTE on `handle_new_user()` from `anon` and `authenticated`.
   This function is a trigger on `auth.users` and should never be called via
   the REST/RPC endpoint — only the database trigger invokes it. Revoking
   EXECUTE closes the `/rest/v1/rpc/handle_new_user` attack surface while
   leaving the trigger fully functional (triggers run with owner privileges).

## Security
- No data is lost; no tables or columns are changed.
- RLS policies remain unchanged.
- The trigger continues to fire on new user signups as before.
*/

-- 1. Fix mutable search_path on update_updated_at_column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- 2. Lock down handle_new_user so it cannot be called via RPC
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM authenticated;
