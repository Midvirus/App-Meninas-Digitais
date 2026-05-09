package com.meninasdigitais.service;

import com.meninasdigitais.dto.request.ObservacaoRequest;
import com.meninasdigitais.entity.ObservacaoPrivada;
import com.meninasdigitais.entity.Usuario;
import com.meninasdigitais.repository.ObservacaoPrivadaRepository;
import com.meninasdigitais.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ObservacaoService {

    private final ObservacaoPrivadaRepository observacaoRepository;
    private final UsuarioRepository usuarioRepository;

    // RF10 - registrar observação privada
    public ObservacaoPrivada registrar(Long tutorandaId, Usuario tutora, ObservacaoRequest req) {
        Usuario tutoranda = usuarioRepository.findById(tutorandaId)
                .orElseThrow(() -> new RuntimeException("Tutoranda não encontrada."));
        ObservacaoPrivada obs = ObservacaoPrivada.builder()
                .tutora(tutora)
                .tutoranda(tutoranda)
                .conteudo(req.getConteudo())
                .build();
        return observacaoRepository.save(obs);
    }

    // RF10 - listar observações de uma tutoranda (tutora ou admin)
    public List<ObservacaoPrivada> listar(Long tutoraId, Long tutorandaId) {
        return observacaoRepository.findByTutoraIdAndTutorandaId(tutoraId, tutorandaId);
    }
}