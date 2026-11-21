# musica-delta-idiomas

Idiomas y cargador de **Delta Música**.

- `idiomas.json`: lista de idiomas y su versión.
- `es.json`, `en.json`, `zh.json`, `fr.json`: textos de cada idioma. **Solo datos JSON, nunca código.**
- `cargador.lua`: detecta el idioma, descarga (o reutiliza) su archivo y abre el reproductor.

## Cómo funciona
1. El cargador mira el idioma del jugador (o `DeltaMusica/idioma.txt`, o `getgenv().DeltaMusicaIdiomaForzado`).
2. Baja `idiomas.json` y el archivo de ese idioma a `DeltaMusica/Idiomas/`. Si ya lo tiene en la misma versión, no vuelve a bajarlo. Sin internet usa lo guardado.
3. Deja el código en `getgenv().DeltaMusicaIdioma` y ejecuta el reproductor, que lee ese archivo. Si algo falla, el reproductor usa el español que lleva incrustado.

## Añadir o corregir un idioma
- Copia `en.json`, traduce solo los valores (no cambies las claves ni los `{1}`, `{2}`) y súbelo con otro código (`pt.json`).
- Añádelo a `idiomas.json`. Si corriges un idioma existente, sube su `version` para que los usuarios lo vuelvan a bajar.
