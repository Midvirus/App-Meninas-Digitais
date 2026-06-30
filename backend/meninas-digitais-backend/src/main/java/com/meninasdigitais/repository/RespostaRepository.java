package com.meninasdigitais.repository;

import com.meninasdigitais.entity.Resposta;
import com.meninasdigitais.enums.ChallengeStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RespostaRepository extends JpaRepository<Resposta, Long> {

    // RF08 - respostas por desafio (para tutora validar)
    List<Resposta> findByDesafioId(Long desafioId);

    // RF06 - resposta de uma tutoranda em um desafio específico
    Optional<Resposta> findByDesafioIdAndTutorandaId(Long desafioId, Long tutorandaId);

    // RF11 - histórico da tutoranda
    List<Resposta> findByTutorandaId(Long tutorandaId);

    // RF12 - mural de destaques
    List<Resposta> findByEmDestaqueTrue();

    // RF09 - progresso por desafio
    long countByDesafioId(Long desafioId);
    long countByDesafioIdAndStatus(Long desafioId, ChallengeStatus status);

    // RF17 - taxa de respostas
    @Query("SELECT COUNT(r) FROM Resposta r WHERE r.status <> com.meninasdigitais.enums.ChallengeStatus.PENDENTE")
    long countRespostasEnviadas();

    // Respostas por tutoranda filtradas por status
    List<Resposta> findByTutorandaIdAndStatus(Long tutorandaId, ChallengeStatus status);
}