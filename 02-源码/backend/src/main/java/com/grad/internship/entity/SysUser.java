package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 系统用户。对应表 sys_user。
 */
@Data
@TableName("sys_user")
public class SysUser {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 登录账号 */
    private String username;

    /** BCrypt 密码，不外泄 */
    private String password;

    /** 姓名 */
    private String realName;

    /** 联系电话 */
    private String phone;

    /** 邮箱 */
    private String email;

    /** 头像相对路径 */
    private String avatar;

    /** 角色编码：admin/patrol/care/expert */
    private String roleCode;

    /** 所属组织ID */
    private Long orgId;

    /** 组织名称冗余 */
    private String orgName;

    /** 数据范围：ALL/ORG/SELF */
    private String dataScope;

    /** 状态：1启用 0停用 */
    private Integer status;

    /** 连续登录失败次数 */
    private Integer failCount;

    /** 锁定截止时间 */
    private LocalDateTime lockUntil;

    /** 最近登录时间 */
    private LocalDateTime lastLoginTime;


    /** 学号（学生） */
    private String studentNo;

    /** 专业 */
    private String major;

    /** 年级 */
    private String grade;

    /** 所属企业ID（企业导师） */
    private Long companyId;

    /** 创建时间 */
    private LocalDateTime createTime;
}
