# Mammon Android

Aplicativo Android em **Kotlin + Jetpack Compose** baseado nas referências visuais enviadas: tema preto, menu lateral, seletor Chat/Work, composer expansível, configurações em cartões, tela de uso/limites, plugins e perfil.

## Identidade

- Nome: **Mammon**
- Logo: `app/src/main/res/drawable/mammon_logo.jpg`
- A logo usada é a imagem fornecida para este projeto.
- O app não usa nome nem logo da OpenAI.

## Pensamento visível

As respostas possuem um painel **Pensamento** expansível. Ele foi implementado como um **resumo de raciocínio para exibição ao usuário**, não como cadeia de pensamento interna do modelo.

## Estado atual

A UI e a navegação estão funcionais. O chat usa uma resposta local de demonstração para permitir testar o fluxo sem chave de API. Depois, o provedor de IA pode ser conectado na camada de dados.

## Abrir

1. Abra o repositório no Android Studio.
2. Aguarde o Gradle Sync.
3. Rode o módulo `app` em Android 8.0+ (API 26+).
