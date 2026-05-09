package com.meninasdigitais.service;

import com.meninasdigitais.entity.Desafio;
import com.meninasdigitais.entity.Resposta;
import com.meninasdigitais.entity.Usuario;
import com.meninasdigitais.enums.ChallengeStatus;
import com.meninasdigitais.repository.DesafioRepository;
import com.meninasdigitais.repository.RespostaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RespostaService {

    private final RespostaRepository respostaRepository;
    private final DesafioRepository desafioRepository;

    private final String uploadDir = "uploads/respostas/";

    // RF06 - enviar resposta (texto, link, arquivo)
    public Resposta enviarResposta(Long desafioId, Usuario tutoranda,
                                   String textoResposta, String linkExterno,
                                   MultipartFile arquivo) throws IOException {

        Desafio desafio = desafioRepository.findById(desafioId)
                .orElseThrow(() -> new RuntimeException("Desafio não encontrado."));

        // Verifica se já enviou
        respostaRepository.findByDesafioIdAndTutorandaId(desafioId, tutoranda.getId())
                .ifPresent(r -> { throw new RuntimeException("Você já enviou uma resposta para este desafio."); });

        Resposta resposta = Resposta.builder()
                .desafio(desafio)
                .tutoranda(tutoranda)
                .textoResposta(textoResposta)
                .linkExterno(linkExterno)
                .status(ChallengeStatus.ENVIADO)
                .build();

        // Upload de arquivo
        if (arquivo != null && !arquivo.isEmpty()) {
            String nomeArquivo = UUID.randomUUID() + "_" + arquivo.getOriginalFilename();
            Path caminho = Paths.get(uploadDir + nomeArquivo);
            Files.createDirectories(caminho.getParent());
            Files.write(caminho, arquivo.getBytes());
            resposta.setArquivoUrl(uploadDir + nomeArquivo);
        }

        return respostaRepository.save(resposta);
    }

    // RF11 - painel da tutoranda
    public List<Resposta> minhasRespostas(Long tutorandaId) {
        return respostaRepository.findByTutorandaId(tutorandaId);
    }
}