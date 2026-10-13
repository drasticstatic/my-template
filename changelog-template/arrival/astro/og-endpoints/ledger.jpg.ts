// The ledger's social card: /og/ledger.jpg (static, built once per build). Ledger v2: no counts on
// the card. A share preview lives for weeks in other apps' caches, so a number on it goes stale;
// the page itself says how many changes there are.
import { pageCard } from "../../og/cards";

export const GET = () =>
  pageCard({
    eyebrow: "ORG AstroLog · Ledger",
    kicker: "Every change, in plain words",
    title: "ORG's code, in plain words",
    summary: "Every public change, grouped by day and by kind and linked to the change itself, with private work shown masked so you can watch it move.",
    meta: "Refreshed every day",
  });
