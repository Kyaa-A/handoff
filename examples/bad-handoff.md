<!--
Example: a BAD handoff note, the same work as examples/good-handoff.md written wrong.
What makes it fail a resume:
  - It is a transcript, not state. The reader must reconstruct where things stand.
  - Relative dates ("today", "yesterday") that lie a week later.
  - Pastes code and logs instead of pointing at path:line and commit SHAs.
  - No single next step up top; the reader has to hunt for what to do.
  - Confirmed and assumed work are mixed, so a stale claim looks done.
  - Decisions are stated without the why, so they get re-litigated.
-->

# Webhook stuff

So today I was working on the Stripe thing. First I noticed the wallet was getting
credited twice sometimes, which was weird, so I spent a while adding logging and
replaying events and yeah it definitely double-credits. Then yesterday we talked
about how to fix it and as discussed above I added a Set to track the event ids:

```ts
const seen = new Set<string>();
export async function handleWebhook(event: Stripe.Event) {
  if (seen.has(event.id)) return;
  seen.add(event.id);
  // ... credit the wallet ...
}
```

This works now, the test passes I think. We should probably use the database instead
at some point but the Set is fine for now. Also we might need to do something about
multiple instances but I'm not sure.

Next I was going to look at the migration but ran out of time. There's also a question
about backfilling but we can figure that out later. The credit logic is in the webhook
file somewhere around the middle. Everything is basically done except the database
part and maybe testing it more.

Oh and I committed some of this but not all of it.
