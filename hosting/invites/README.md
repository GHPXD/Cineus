# Convites HTTPS

Conteúdo estático pronto para hospedar. Não há domínio ou produto de loja inventado. O jogo funciona com o código e esquema `cineus://` enquanto `CINEUS_PUBLIC_BASE_URL` estiver vazio.

1. Publique esta pasta em uma origem HTTPS. Rotas `/challenge/*` e `/friend/*` devem servir `index.html` com status 200; CSS/JS/JSON usam a raiz da origem.
2. Preencha `stores.json` apenas com URLs reais da Google Play e App Store. Copie `web/privacy.html` para a raiz publicada.
3. Publique `/.well-known/assetlinks.json` com package `dev.cineus.cineus`, relação `delegate_permission/common.handle_all_urls` e SHA-256 do certificado de assinatura de produção. Para Apple, publique `apple-app-site-association` com seu Team ID, bundle ID e caminhos `/challenge/*` e `/friend/*`.
4. Configure a origem em `--dart-define=CINEUS_PUBLIC_BASE_URL=https://SEU-DOMINIO`. O Gradle deriva o host e a verificação Android dessa definição; sem ela usa um domínio reservado `.invalid` e desliga a verificação. No iOS, selecione `Runner/RunnerAppLinks.entitlements` no Xcode e configure `CINEUS_PUBLIC_HOST` com o host real, além da mesma definição Dart. A associação exige domínio e certificados reais. Não envie arquivos com IDs fictícios.
5. Use cabeçalhos `Content-Security-Policy: default-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'`, `Referrer-Policy: no-referrer`, `X-Content-Type-Options: nosniff`. Não inclua trackers nem previews de filmes no HTML de convite.

O botão de abertura exige um toque. Se o app estiver ausente, a página mantém o código e as instruções de instalação; não há redirecionamento automático em loop. Confrontos expirados ou ocupados são rejeitados no servidor.
