package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 字典。对应表 sys_dict。
 */
@Data
@TableName("sys_dict")
public class SysDict {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 字典类型 */
    private String dictType;

    /** 显示名 */
    private String dictLabel;

    /** 字典值 */
    private String dictValue;

    /** 排序 */
    private Integer sortNo;

    /** 状态 */
    private Integer status;
}
