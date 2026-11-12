# SoundDex

## Lancer avec Supabase

Les paramètres Supabase ne sont jamais écrits dans le dépôt. Le fichier `.env`
n’est pas chargé automatiquement par Flutter dans cette configuration. Lance
l’application avec l’URL du projet et la clé publique `anon` :

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://ton-projet.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=ta-cle-anon
```

Sans ces paramètres, SoundDex reste utilisable hors ligne en mode invité, mais
les fonctions de compte et les onglets sociaux restent indisponibles.
Si l’application est lancée avec le bouton « Run » de VS Code, ajoute ces deux
valeurs dans la configuration de lancement ou lance la commande ci-dessus.

La clé doit être la clé `anon`/`publishable` du tableau Supabase (`sb_publishable_`
ou l’ancienne clé JWT `anon`). Ne mets jamais une clé `sb_secret_` ou
`service_role` dans l’application. Si une telle clé a été exposée, révoque-la
immédiatement dans Supabase et génère-en une nouvelle.

Le fichier [.env.example](.env.example) indique les noms attendus. Les fichiers
`.env` sont ignorés par Git.
