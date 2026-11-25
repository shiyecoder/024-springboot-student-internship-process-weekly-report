package com.grad.internship.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.internship.entity.SysOrg;
import org.apache.ibatis.annotations.Mapper;

/** 组织（养护单位/管理部门） 数据访问。 */
@Mapper
public interface SysOrgMapper extends BaseMapper<SysOrg> {
}
