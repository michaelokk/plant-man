# plant-man

A pricing questionnaire for gardeners (in Hebrew). It collects how they price today, their real past jobs with photos, and what they want from a pricing app.

Live page: https://michaelokk.github.io/plant-man-/

## How it works

- `index.html` is the whole form: a single static page with no build step, hosted on GitHub Pages.
- Answers save in the phone's browser as the person types. They also go to Supabase (INKnerd project) through the `save_gardener_response` function.
- With no connection, the answers wait on the phone and send when the connection comes back.
- Job photos are shrunk on the phone to 1600px JPEG, then uploaded to the public `gardener-photos` storage bucket. Each job keeps its photo URLs.
- Each person gets a random id, stored in their browser. Coming back to the link on the same phone keeps editing the same row.
- The "copy all answers" button gives a WhatsApp-ready text version that includes the photo links.

## One-time Supabase setup

Run `supabase/questionnaire.sql` in the INKnerd project: open SQL Editor, choose New query, paste the file and click Run. It creates:

- `gardener_responses`: one row per respondent, with all answers in `data` (jsonb). Row-level security is on, so the public key can't read it.
- `save_gardener_response(p_id, p_data)`: the only way the form writes.
- The `gardener-photos` bucket: public read, upload-only for the form.
- `gardener_responses_overview`: name, number of jobs and last update, for a quick look.

## Reading the answers

Use Supabase's Table Editor and open `gardener_responses` or `gardener_responses_overview`, or run this query:

```sql
select data from gardener_responses order by updated_at desc;
```
