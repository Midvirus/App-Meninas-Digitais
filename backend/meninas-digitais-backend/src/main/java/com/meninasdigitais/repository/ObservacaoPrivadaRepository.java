package com.meninasdigitais.repository;

import com.meninasdigitais.entity.ObservacaoPrivada;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ObservacaoPrivadaRepository extends JpaRepository<ObservacaoPrivada, Long> {

    // RF10 - observações de uma tutora sobre uma tutoranda específica
    List<ObservacaoPrivada> findByTutoraIdAndTutorandaId(Long tutoraId, Long tutorandaId);

    // Admin pode ver todas de uma tutoranda
    List<ObservacaoPrivada> findByTutorandaId(Long tutorandaId);
}