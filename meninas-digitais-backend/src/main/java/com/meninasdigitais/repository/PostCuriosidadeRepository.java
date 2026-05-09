package com.meninasdigitais.repository;

import com.meninasdigitais.entity.PostCuriosidade;
import com.meninasdigitais.enums.PostCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PostCuriosidadeRepository extends JpaRepository<PostCuriosidade, Long> {

    // RF14 - todos os posts ativos ordenados por data
    List<PostCuriosidade> findByAtivoTrueOrderByCriadoEmDesc();

    // RF14 - filtro por categoria
    List<PostCuriosidade> findByCategoriaAndAtivoTrue(PostCategory categoria);

    // Posts de uma tutora específica
    List<PostCuriosidade> findByTutoraId(Long tutoraId);
}