package com.meninasdigitais.service;

import com.meninasdigitais.dto.request.CriarDesafioRequest;
import com.meninasdigitais.dto.request.FeedbackRespostaRequest;
import com.meninasdigitais.dto.request.DestaqueRequest;
import com.meninasdigitais.entity.Desafio;
import com.meninasdigitais.entity.Resposta;
import com.meninasdigitais.entity.Usuario;
import com.meninasdigitais.enums.ChallengeStatus;
import com.meninasdigitais.repository.DesafioRepository;
import com.meninasdigitais.repository.RespostaRepository;
import com.meninasdigitais.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class DesafioService {

    private final DesafioRepository desafioRepository;
    private final RespostaRepository respostaRepository;
    private final UsuarioRepository usuarioRepository;
    private final com.meninasdigitais.repository.NotificacaoRepository notificacaoRepository;

    // RF04 e RF05 - criar e publicar desafio
    public Desafio criarDesafio(CriarDesafioRequest req, Usuario tutora) {
        Desafio desafio = Desafio.builder()
                .titulo(req.getTitulo())
                .descricao(req.getDescricao())
                .nivelDificuldade(req.getNivelDificuldade())
                .prazoEntrega(req.getPrazoEntrega())
                .tipoResposta(req.getTipoResposta())
                .tags(req.getTags())
                .paraTodasTutorandas(req.isParaTodasTutorandas())
                .tutora(tutora)
                .build();

        // RF05 - tutorandas específicas
        if (!req.isParaTodasTutorandas() && req.getTutorandasEspecificasIds() != null) {
            List<Usuario> especificas = usuarioRepository.findAllById(req.getTutorandasEspecificasIds());
            desafio.setTutorandasEspecificas(especificas);
        }

        return desafioRepository.save(desafio);
    }

    // RF07 - desafios visíveis para uma tutoranda
    public List<Desafio> listarDesafiosParaTutoranda(Long tutorandaId, Long tutoraId) {
        List<Desafio> desafios = new ArrayList<>();

        // Busca desafios para todas as tutorandas (da tutora vinculada)
        if (tutoraId != null) {
            desafios.addAll(desafioRepository.findByTutoraIdAndParaTodasTutorandasTrueAndAtivo(tutoraId, true));
        }

        // Busca desafios específicos para essa tutoranda
        desafios.addAll(desafioRepository.findDesafiosEspecificosByTutorandaId(tutorandaId));

        // Remove duplicatas caso o mesmo desafio apareça nas duas buscas
        return desafios.stream()
                .distinct()
                .collect(java.util.stream.Collectors.toList());
    }

    // RF08 - listar respostas de um desafio (para tutora validar)
    public List<Resposta> listarRespostasPorDesafio(Long desafioId) {
        return respostaRepository.findByDesafioId(desafioId);
    }

    // RF08 - dar feedback e validar resposta
    public Resposta feedbackResposta(Long respostaId, FeedbackRespostaRequest req) {
        Resposta resposta = respostaRepository.findById(respostaId)
                .orElseThrow(() -> new RuntimeException("Resposta não encontrada."));
        resposta.setFeedbackTutora(req.getFeedback());
        resposta.setFeedbackEm(LocalDateTime.now());
        resposta.setStatus(req.isAprovado() ? ChallengeStatus.VALIDADO : ChallengeStatus.ENVIADO);
        return respostaRepository.save(resposta);
    }

    // RF09 - painel de progresso por desafio
    public Map<String, Object> progressoDesafio(Long desafioId) {
        long total = respostaRepository.countByDesafioId(desafioId);
        long validadas = respostaRepository.countByDesafioIdAndStatus(desafioId, ChallengeStatus.VALIDADO);
        long enviadas = respostaRepository.countByDesafioIdAndStatus(desafioId, ChallengeStatus.ENVIADO);
        Map<String, Object> progresso = new HashMap<>();
        progresso.put("total", total);
        progresso.put("enviadas", enviadas);
        progresso.put("validadas", validadas);
        progresso.put("percentualValidado", total > 0 ? (validadas * 100.0 / total) : 0);
        return progresso;
    }

    // RF13 - solicitar destaque
    public Resposta solicitarDestaque(Long respostaId, DestaqueRequest req) {
        Resposta resposta = respostaRepository.findById(respostaId)
                .orElseThrow(() -> new RuntimeException("Resposta não encontrada."));
        resposta.setDestaqueSolicitado(true);
        resposta.setComentarioDestaque(req.getComentarioDestaque());
        
        com.meninasdigitais.entity.Notificacao notificacao = com.meninasdigitais.entity.Notificacao.builder()
                .usuario(resposta.getTutoranda())
                .mensagem("Sua tutora achou sua resposta excelente e quer publicá-la no mural de destaques! Você autoriza?")
                .tipo("SOLICITACAO_DESTAQUE")
                .referenciaId(resposta.getId())
                .lida(false)
                .build();
        notificacaoRepository.save(notificacao);
        
        return respostaRepository.save(resposta);
    }

    public Resposta responderSolicitacaoDestaque(Long respostaId, boolean aprovado) {
        Resposta resposta = respostaRepository.findById(respostaId)
                .orElseThrow(() -> new RuntimeException("Resposta não encontrada."));
        
        if (aprovado) {
            resposta.setEmDestaque(true);
            resposta.setDestacadoEm(LocalDateTime.now());
        } else {
            resposta.setEmDestaque(false);
        }
        resposta.setDestaqueSolicitado(false);
        return respostaRepository.save(resposta);
    }

    // RF18 - remover destaque (moderação admin)
    public void removerDestaque(Long respostaId) {
        Resposta resposta = respostaRepository.findById(respostaId)
                .orElseThrow(() -> new RuntimeException("Resposta não encontrada."));
        resposta.setEmDestaque(false);
        resposta.setComentarioDestaque(null);
        respostaRepository.save(resposta);
    }

    // RF18 - desativar desafio (moderação admin)
    public void desativarDesafio(Long desafioId) {
        Desafio d = desafioRepository.findById(desafioId)
                .orElseThrow(() -> new RuntimeException("Desafio não encontrado."));
        d.setAtivo(false);
        desafioRepository.save(d);
    }

    // RF12 - mural de destaques
    public List<Resposta> listarDestaques() {
        return respostaRepository.findByEmDestaqueTrue();
    }
}