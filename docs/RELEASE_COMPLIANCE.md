# Cineus — Release Compliance Checklist

Esta checklist cobre os itens de conformidade que precisam estar resolvidos antes de publicar uma build nas lojas.

## Privacidade e termos

- [x] Política de Privacidade versionada em `docs/privacy.html`
- [x] Termos de Uso versionados em `docs/terms.html`
- [x] Política/termos também acessíveis dentro do app
- [x] O texto descreve o modelo offline-first atual: sem conta e sem backend próprio de sincronização
- [ ] Publicar `docs/` em uma URL pública estável e usar essa URL nos campos das lojas

## TMDB

A documentação oficial do TMDB exige que a atribuição esteja em uma seção do tipo **About/Credits**, use o aviso obrigatório e utilize um logo oficial/aprovado.

- [x] Seção `Sobre e créditos` acessível pelo app
- [x] Aviso obrigatório presente, sem tradução/substituição:
  `This product uses the TMDB API but is not endorsed or certified by TMDB.`
- [x] O TMDB é identificado como fonte de parte dos metadados/imagens do catálogo
- [ ] Adicionar ao bundle um logo oficial aprovado do TMDB sem alterar cor/proporção
- [ ] Antes de ativar Ads/Pass, obter/confirmar a licença comercial apropriada do TMDB e documentar a autorização aplicável

Referência oficial: https://developer.themoviedb.org/docs/faq

## Pôsteres locais / propriedade intelectual

Os pôsteres continuam bundlados em `assets/posters/`; nenhum carregamento remoto
é necessário durante o jogo.

- [x] runtime offline: pôsteres são assets locais
- [ ] documentar a origem/licença aplicável aos pôsteres distribuídos no bundle
- [ ] manter prova de autorização disponível para revisão das lojas quando aplicável
- [ ] não confundir armazenamento local com autorização de copyright

## Android release signing

- [x] Credenciais de upload continuam fora do Git
- [x] Build `release` local/publicável falha se `android/key.properties` estiver ausente
- [x] CI pode usar a chave debug somente via `CINEUS_ALLOW_DEBUG_SIGNED_RELEASE=true`
- [x] O bypass de CI é explicitamente marcado como artefato não publicável
- [ ] Antes de publicar, gerar/configurar a upload key definitiva e guardar backup seguro

## iOS signing

- [x] CI compila Release sem assinatura com Xcode/iOS SDK 26+
- [ ] Configurar Team/Signing de distribuição na máquina usada para App Store Connect
- [ ] Validar Archive/IPA assinado antes da submissão

## Store metadata

- [ ] Definir URLs públicas finais de Privacy Policy e Support
- [ ] Revisar descrição, subtítulo, keywords e classificação etária
- [ ] Revisar screenshots em todos os tamanhos exigidos
- [x] Remover versão hardcoded das strings de splash/produto
- [ ] Preencher declarações de coleta de dados de acordo com a build final

## Monetização

- [x] gameplay essencial permanece gratuito por política de domínio
- [x] rewarded e Pass estão atrás de interfaces testáveis e fail-closed
- [x] build sem configuração comercial não exibe monetização falsa
- [ ] criar ad-unit IDs e produtos reais nas lojas
- [ ] conectar SDKs oficiais e consentimento somente na release monetizada
- [ ] validar compra/restauração/reward em tracks de teste
- [ ] atualizar Privacy/App Privacy/Data Safety com os SDKs finais

## Gate automatizado

`scripts/validate_release_compliance.py` roda no job `Analyze & test` e impede regressões nos arquivos legais, rotas, aviso do TMDB e fail-closed do signing Android.
