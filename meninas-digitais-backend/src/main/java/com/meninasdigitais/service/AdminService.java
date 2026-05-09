package com.meninasdigitais.service;

import com.meninasdigitais.enums.Role;
import com.meninasdigitais.repository.DesafioRepository;
import com.meninasdigitais.repository.RespostaRepository;
import com.meninasdigitais.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UsuarioRepository usuarioRepository;
    private final DesafioRepository desafioRepository;
    private final RespostaRepository respostaRepository;

    // RF17 - painel de indicadores gerais
    public Map<String, Object> indicadores() {
        Map<String, Object> dados = new HashMap<>();
        dados.put("tutorandasAtivas", usuarioRepository.countByRoleAndAtivo(Role.TUTORANDA, true));
        dados.put("tutorasAtivas", usuarioRepository.countByRoleAndAtivo(Role.TUTORA, true));
        dados.put("desafiosEmAndamento", desafioRepository.countByAtivo(true));
        dados.put("totalRespostasEnviadas", respostaRepository.countRespostasEnviadas());
        return dados;
    }
}