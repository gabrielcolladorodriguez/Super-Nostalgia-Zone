# Bygone — fork of Super Nostalgia Zone

This is a fork of **[MaximumADHD/Super-Nostalgia-Zone](https://github.com/MaximumADHD/Super-Nostalgia-Zone)**,
the framework that recreates the 2008 ROBLOX experience on the modern engine.

**All credit for the engine goes to [MaximumADHD](https://github.com/MaximumADHD)**
(formerly CloneTrooper1019). The camera, the mouse, the chat, the classic GUI,
the stud and inlet surfaces, the old heads and faces, the explosions and the
FilteringEnabled-safe reimplementations of the classic tools are all his work.

The original is licensed **MPL-2.0**, and its README asks that derivative work
be credited, linked back, and kept in a public fork for the record. That is what
this repository is for. Every change is listed below.

---

## What this fork adds

Everything new lives in two folders that do not exist upstream, so the original
tree stays recognisable:

### `Local/` — running the framework standalone

Upstream boots from `core.lua`, which is published as a MainModule and refuses
to run anywhere else:

```lua
if isOnline and game.GameId ~= 123949867 then
    script:Destroy()
    return
end
```

- **`Local/Bootstrap.server.lua`** replaces that boot phase for a self-contained
  place. It does what `core.lua` did — checks `FilteringEnabled`, disables
  `PlayerScriptsLoader`, forces the `StarterPlayer` settings, creates the default
  sky — plus what the modern engine needs: hiding the `TextChatService` UI and
  zeroing the name/health display distances.
- **`Local/Map.model.json`** and **`Local/generate_map.py`** — a sample
  brickbattle sandbox map.

### `Hub/` — a menu for browsing many classic places

- **`Hub/Menu/Menu.client.lua`** — a 2008-styled dialog listing the places of the
  universe by category, with search, provenance labels and teleporting. Scales
  for phones and tablets.
- **`Hub/Lobby.model.json`**, **`Hub/generate_lobby.py`** — the lobby.
- **`Hub/Herramientas/CrearLugares.server.lua`** — one-shot utility that creates
  one place per catalogue entry with `AssetService:CreatePlaceAsync`. Open Cloud
  can update a place but cannot create one, so this has to run in-game.

### Rojo project files

`place.project.json`, `hub.project.json`, `inject.project.json` and
`serve.project.json` — building the sandbox, the hub, the injectable engine, and
a code-only project for live syncing.

---

## Changes to upstream files

Four files are touched. Every edit is marked with a `-- [fork]` comment.

| File | Change | Why |
|---|---|---|
| `Shared/PlaceData.lua` | `GetGamePlacesAsync()` wrapped in `pcall` | It throws in a local file or without API access, which took the whole module down. |
| `Server/Scripts/Badges.server.lua` | same call, same fix | same reason |
| `Server/Scripts/Regeneration.server.lua` | accepts a `StringValue` (model name) as well as an `ObjectValue` | Rojo cannot write cross-service references from a `.project.json`. |
| `UI/Topbar/Topbar.client.lua` | Exit reads `ReplicatedStorage.HubPlaceId` instead of the hardcoded `998374377` | Upstream teleports to MaximumADHD's own hub. In any other universe that throws the player into a stranger's game. With no value set, it now teleports nowhere. |
| `UI/Mouse/Mouse.client.lua` | over a GUI the cursor becomes the classic arrow instead of a non-existent image id; the cursor moves to its own top `ScreenGui` | Upstream hides the cursor over any interface — invisible in the original game because there is barely any GUI to hover, but with a full-screen menu you are left with no cursor at all. |
| `UI/Messages/init.client.lua` | a `Message` whose text mentions loading and has not changed in 30s is hidden | Old places show "Loading models..." and clear it when `InsertService:LoadAsset` returns. That call no longer succeeds, so the message covered the screen forever. Restricted to loading wording on purpose: several places use `Message` as a permanent HUD. |

---

## Credit for the places themselves

This fork is only the engine. The classic places it is used with belong to their
original authors — ROBLOX and its staff (Shedletsky/Telamon, builderman,
clockwork, ReeseMcBlox) and the community creators of 2006-2010. They are
preserved by community archives on GitHub, not by this repository, and are not
redistributed here.

## Licence

MPL-2.0, same as upstream. See `LICENSE`.

---

## Update: Bygone is a builder now

The project changed direction. Republishing archived places was legally shaky
even after filtering by licence — an author's "uncopylocked" was never a
redistribution grant, and a third party putting a licence on someone else's
archived work grants nothing at all. So the archive was retired entirely and
Bygone became a place where people build their own classic-style places.

New folders, all outside the upstream tree:

### `Builder/Shared/Serializer.lua`
Turns a build into a table and back. Numbered arrays instead of named keys
because a DataStore key holds 4 MB and it is the difference between fitting and
not. `Sanear()` is the trust boundary: the editor runs on the client, so nothing
it sends is believed until this has checked every part's size, position and
rotation for NaNs, infinities and absurd values.

### `Builder/Server/CreationStore.lua`
Three stores: the creations themselves, an index per user, and an
OrderedDataStore for the gallery — a normal DataStore cannot sort or page, so
listing "the ten most recent" would mean reading every key. Every call is
wrapped and retried with backoff; Roblox throttles these more than people expect.

### `Builder/Server/BuilderService.server.lua`
Ownership is checked against what is stored, never against what the client
claims. Per-player rate limits so nobody can burn the experience's DataStore
quota. Names and descriptions go through `TextService` before anyone else sees
them, and a filter failure rejects the save rather than publishing unfiltered
text.

### `Builder/Client/Editor/`
The editor: free camera, insert, select, drag with stud snapping, rotate,
duplicate, undo/redo, the classic 64-colour BrickColor palette, period
materials and surfaces. Undo keeps whole snapshots rather than per-operation
inverses — at 2,500 parts the memory is cheap and it avoids the class of bug
where undo and redo drift apart.

### `Builder/Server/PlayCreation.server.lua`
Serves one creation per server. The id arrives in the teleport data, not as a
client argument, so nobody can request a private build by typing an id.
