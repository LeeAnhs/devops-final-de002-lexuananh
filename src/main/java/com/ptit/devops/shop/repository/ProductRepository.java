package com.ptit.devops.shop.repository;

import com.ptit.devops.shop.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductRepository extends JpaRepository<Product, Long> {
}
