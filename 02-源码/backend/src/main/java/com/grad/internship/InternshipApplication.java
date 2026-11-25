package com.grad.internship;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * 古树名木养护档案管理系统启动类。
 * 端口 8085、库 new_016 由 application.yml 指定，切换通道时只改配置。
 */
@SpringBootApplication
@MapperScan("com.grad.internship.mapper")
public class InternshipApplication {
    public static void main(String[] args) {
        SpringApplication.run(InternshipApplication.class, args);
    }
}
