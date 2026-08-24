/*
# Add saved_recipes table

## Purpose
Users can save individual recipes/meals they want to reuse. Saved recipes can be
dragged or added to specific days in the weekly meal plan.

## New Tables
1. `saved_recipes`
   - `id` (uuid, PK)
   - `user_id` (uuid, references auth.users, defaults to auth.uid())
   - `name` (text, not null)
   - `meal_type` (text: breakfast/lunch/dinner/snack)
   - `calories` (integer)
   - `protein` (integer)
   - `carbs` (integer)
   - `fat` (integer)
   - `fiber` (integer, default 0) — Ballstoffe
   - `ingredients` (text[], default '{}')
   - `image_url` (text, nullable)
   - `created_at` (timestamptz)
   - `updated_at` (timestamptz)

2. `meal_plan_entries` — individual meal entries that can reference a saved recipe
   - `id` (uuid, PK)
   - `user_id` (uuid, references auth.users, defaults to auth.uid())
   - `date` (date, not null)
   - `recipe_id` (uuid, nullable, references saved_recipes ON DELETE SET NULL)
   - `name` (text, not null)
   - `meal_type` (text: breakfast/lunch/dinner/snack)
   - `calories` (integer, default 0)
   - `protein` (integer, default 0)
   - `carbs` (integer, default 0)
   - `fat` (integer, default 0)
   - `fiber` (integer, default 0)
   - `ingredients` (text[], default '{}')
   - `image_url` (text, nullable)
   - `created_at` (timestamptz)

## Security
- RLS enabled on both tables.
- Owner-scoped CRUD (TO authenticated, auth.uid() = user_id).
- user_id defaults to auth.uid() so inserts work without client passing it.
*/

CREATE TABLE IF NOT EXISTS saved_recipes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  meal_type text NOT NULL DEFAULT 'lunch',
  calories integer NOT NULL DEFAULT 0,
  protein integer NOT NULL DEFAULT 0,
  carbs integer NOT NULL DEFAULT 0,
  fat integer NOT NULL DEFAULT 0,
  fiber integer NOT NULL DEFAULT 0,
  ingredients text[] NOT NULL DEFAULT '{}',
  image_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE saved_recipes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_recipes" ON saved_recipes;
CREATE POLICY "select_own_recipes" ON saved_recipes FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "insert_own_recipes" ON saved_recipes;
CREATE POLICY "insert_own_recipes" ON saved_recipes FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "update_own_recipes" ON saved_recipes;
CREATE POLICY "update_own_recipes" ON saved_recipes FOR UPDATE
  TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "delete_own_recipes" ON saved_recipes;
CREATE POLICY "delete_own_recipes" ON saved_recipes FOR DELETE
  TO authenticated USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS meal_plan_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  date date NOT NULL,
  recipe_id uuid REFERENCES saved_recipes(id) ON DELETE SET NULL,
  name text NOT NULL,
  meal_type text NOT NULL DEFAULT 'lunch',
  calories integer NOT NULL DEFAULT 0,
  protein integer NOT NULL DEFAULT 0,
  carbs integer NOT NULL DEFAULT 0,
  fat integer NOT NULL DEFAULT 0,
  fiber integer NOT NULL DEFAULT 0,
  ingredients text[] NOT NULL DEFAULT '{}',
  image_url text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE meal_plan_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_meal_entries" ON meal_plan_entries;
CREATE POLICY "select_own_meal_entries" ON meal_plan_entries FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "insert_own_meal_entries" ON meal_plan_entries;
CREATE POLICY "insert_own_meal_entries" ON meal_plan_entries FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "update_own_meal_entries" ON meal_plan_entries;
CREATE POLICY "update_own_meal_entries" ON meal_plan_entries FOR UPDATE
  TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "delete_own_meal_entries" ON meal_plan_entries;
CREATE POLICY "delete_own_meal_entries" ON meal_plan_entries FOR DELETE
  TO authenticated USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_saved_recipes_user ON saved_recipes(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_plan_entries_user_date ON meal_plan_entries(user_id, date);

-- Auto-update updated_at for saved_recipes
DROP TRIGGER IF EXISTS trigger_saved_recipes_updated_at ON saved_recipes;
CREATE TRIGGER trigger_saved_recipes_updated_at BEFORE UPDATE ON saved_recipes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
