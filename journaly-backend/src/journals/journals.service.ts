import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateJournalDto } from './dto/create-journal.dto';

@Injectable()
export class JournalsService {
  constructor(private prisma: PrismaService) {}

  async create(createJournalDto: CreateJournalDto) {
    return await this.prisma.journal.create({
      data: createJournalDto,
    });
  }

  async findAll(userId: string) {
    return await this.prisma.journal.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' }
    });
  }

  async findOne(id: string, userId: string) {
    return await this.prisma.journal.findFirst({
      where: { id, userId },
    });
  }

  async remove(id: string, userId: string) {
    return await this.prisma.journal.deleteMany({
      where: { id: id, userId: userId },
    });
  }
}
