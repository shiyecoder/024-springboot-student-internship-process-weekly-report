package com.grad.internship.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.internship.entity.SysDict;
import org.apache.ibatis.annotations.Mapper;

/** 字典 数据访问。 */
@Mapper
public interface SysDictMapper extends BaseMapper<SysDict> {
}
