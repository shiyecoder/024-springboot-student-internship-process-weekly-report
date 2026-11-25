package com.grad.internship.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.internship.entity.InternshipApplication;
import org.apache.ibatis.annotations.Mapper;

/** 实习档案主表 Mapper。 */
@Mapper
public interface InternshipApplicationMapper extends BaseMapper<InternshipApplication> {
}
