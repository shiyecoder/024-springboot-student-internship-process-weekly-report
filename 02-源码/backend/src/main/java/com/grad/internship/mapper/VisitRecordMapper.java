package com.grad.internship.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.internship.entity.VisitRecord;
import org.apache.ibatis.annotations.Mapper;

/** 走访记录 Mapper。 */
@Mapper
public interface VisitRecordMapper extends BaseMapper<VisitRecord> {
}
