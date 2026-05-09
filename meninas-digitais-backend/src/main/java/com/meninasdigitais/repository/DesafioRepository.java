package com.meninasdigitais.repository;

import com.meninasdigitais.entity.Desafio;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.data.repository.query.Param;

import java.util.List;

@Repository
public interface DesafioRepository extends JpaRepository<Desafio, Long> {

    // Desafios publicados por uma tutora
    List<Desafio> findByTutoraIdAndAtivo(Long tutoraId, boolean ativo);

    // RF07 - desafios para todas as tutorandas (para uma tutora específica)
    List<Desafio> findByParaTodasTutorandasTrueAndAtivo(boolean ativo);

    List<Desafio> findByTutoraIdAndParaTodasTutorandasTrueAndAtivo(Long tutoraId, boolean ativo);

    // RF17 - desafios em andamento (ativos)
    long countByAtivo(boolean ativo);

    // Desafios específicos de uma tutoranda
    @Query("SELECT d FROM Desafio d JOIN d.tutorandasEspecificas t WHERE t.id = :tutorandaId AND d.ativo = true")
    List<Desafio> findDesafiosEspecificosByTutorandaId(@Param("tutorandaId") Long tutorandaId);
}