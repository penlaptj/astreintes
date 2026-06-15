# Gravitee APIM devant l'app Astreintes

Cette stack ajoute **Gravitee API Management v4** comme passerelle API devant
l'application `web` (Rails) du projet `astreinte2`. Elle illustre, en local,
les briques attendues sur un poste *Platform Engineer API & Observability* :

- exposition controlee d'une API (path-based, rate limiting, transformation de headers),
- catalogue et portail developpeur,
- diffusion d'evenements vers des consommateurs externes via **Webhook**,
- collecte des metriques et logs d'acces dans Elasticsearch.

## Topologie

```
  client --> :8082 (gravitee-gateway) --> host.docker.internal:3000 (astreintes web)
                       |
                       +--> mongodb  (config & rate-limit counters)
                       +--> elasticsearch (acces logs & analytics)
                       +--> :8083 management-api  (CRUD APIs)
                       +--> :8084 management-ui   (console admin)
                       +--> :8085 portal-ui       (portail developpeur)
```

## Demarrage

Prerequis : la stack principale `astreinte2` doit tourner (l'app `web` ecoute
sur `localhost:3000`). Sur Docker Desktop Windows/Mac, `host.docker.internal`
resout l'hote depuis les conteneurs Gravitee.

```sh
# Depuis la racine du repo
docker compose up -d                                # stack astreintes
docker compose -f gravitee/docker-compose.gravitee.yml up -d   # stack gravitee

# Attendre ~60s que Mongo + ES + APIM soient prets
docker compose -f gravitee/docker-compose.gravitee.yml ps
```

Acces UI (login par defaut : `admin` / `admin`) :

| Service           | URL                       |
|-------------------|---------------------------|
| Console Admin     | http://localhost:8084     |
| Portail Dev       | http://localhost:8085     |
| Management API    | http://localhost:8083     |
| Gateway (proxy)   | http://localhost:8082     |

## Import declaratif des APIs

Les definitions d'API sont versionnees dans `apis/`. Pour les pousser sans
passer par la console :

```sh
chmod +x gravitee/scripts/*.sh
./gravitee/scripts/import-api.sh ./gravitee/apis/astreintes-api.json
./gravitee/scripts/import-api.sh ./gravitee/apis/webhook-subscriptions.json
```

L'API est ensuite a **deployer** et **demarrer** dans la console (un clic).

## Test rapide

```sh
./gravitee/scripts/smoke-test.sh
# attendu : HTTP 200 puis HTTP 429 quand la limite (100 req/min) est atteinte
```

## Ce que la conf met en place

`apis/astreintes-api.json` (API REST proxy) :

- `rate-limit` 100 req/min par consommateur avec headers `X-RateLimit-*`,
- `transform-headers` ajoute `X-Forwarded-Through` et `X-Request-Id` cote backend,
- `transform-headers` strip `Server` / `X-Powered-By` cote reponse,
- logging des headers en entree + sortie pour analytics ES.

`apis/webhook-subscriptions.json` (API event-driven) :

- entrypoint `webhook` (QoS at-least-once),
- source mockee toutes les 5s pour valider la chaine de souscription,
- enrichissement des messages avec un header `X-Event-Source`.

## Observabilite

Les logs et compteurs d'acces partent dans Elasticsearch. Pour pousser ces
metriques vers la stack Prometheus/Grafana deja utilisee dans le projet :

- exposer le port de monitoring interne du gateway (`gravitee_services_core_http_port: 18082`) ;
- scraper l'endpoint `/_node/monitor` depuis Prometheus.

Exemple de job dans `prometheus.yml` :

```yaml
scrape_configs:
  - job_name: gravitee-gateway
    metrics_path: /_node/monitor
    basic_auth: { username: admin, password: adminadmin }
    static_configs:
      - targets: ["gravitee_gateway:18082"]
```

## Nettoyage

```sh
docker compose -f gravitee/docker-compose.gravitee.yml down -v
```
