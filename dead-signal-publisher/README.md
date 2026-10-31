# Still Here — Mistério

Esta branch prepara uma experiência única de exploração no casarão original.

- Universo Roblox principal: `9421311218`
- Place: `118064584465155`
- Branch: `dead-signal-publisher`
- Build: `still-here-mystery-only-v1`

A pessoa entra no casarão após uma tela de carregamento em português. A versão não tem menu principal personalizado, créditos na tela, fluxo de grupo, armas ou câmera em primeira pessoa. Os gatilhos de história, o ritual, a nuvem sobre a casa e o carro batido são removidos. A porta principal abre sem a chave, e as cadeiras existentes recebem a opção `Sentar`.

O botão de pausa e os convites padrão do Roblox continuam disponíveis. As configurações do jogo ficam no botão de engrenagem.

## Build e publicação

`publish.mjs --dry-run` confere se os arquivos da versão de um único mapa estão presentes. O publicador monta, verifica e publica somente o Place do Mistério. Se o Universe separado da estufa ainda estiver ativo, ele o desativa depois da verificação; se uma etapa posterior falhar, a recuperação tenta reativá-lo junto com o rollback do Place principal.

A publicação não roda quando apenas os arquivos-fonte mudam. Ela é iniciada pela atualização de `release.trigger` após a revisão.
