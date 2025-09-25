#!/usr/bin/env python3
"""
자동화된 식물 모니터링 스케줄러
- 정기적 이미지 촬영
- 자동 분석 및 데이터 정리
- 원본 이미지 보존 중심
"""

import schedule
import time
import threading
from datetime import datetime, timedelta
from plant_monitoring_system import PlantMonitoringSystem
import logging
from pathlib import Path

class AutomatedPlantMonitor:
    """자동화 식물 모니터링 클래스"""
    
    def __init__(self, config_override: dict = None):
        """
        자동 모니터링 시스템 초기화
        
        Args:
            config_override: 설정 오버라이드
        """
        self.monitoring_system = PlantMonitoringSystem()
        self.is_running = False
        self.setup_logging()
        
        # 기본 자동 모니터링 설정
        self.auto_config = {
            "interval_minutes": 60,  # 1시간마다
            "active_hours": (8, 18),  # 8시~18시만 촬영
            "plants_to_monitor": [],  # 빈 리스트면 모든 등록된 식물
            "max_daily_captures": 10,  # 하루 최대 촬영 횟수
            "cleanup_days": 30,  # 30일 이후 정리
        }
        
        if config_override:
            self.auto_config.update(config_override)
        
        self.daily_capture_count = {}
        self.setup_schedules()
    
    def setup_logging(self):
        """로깅 설정"""
        log_dir = self.monitoring_system.base_path / "logs"
        log_dir.mkdir(exist_ok=True)
        
        # 일별 로그 파일
        log_file = log_dir / f"monitoring_{datetime.now().strftime('%Y%m%d')}.log"
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file, encoding='utf-8'),
                logging.StreamHandler()
            ]
        )
        
        self.logger = logging.getLogger(__name__)
    
    def setup_schedules(self):
        """스케줄 설정"""
        
        # 정기 촬영 스케줄
        interval = self.auto_config["interval_minutes"]
        schedule.every(interval).minutes.do(self.scheduled_capture)
        
        # 일별 정리 작업 (매일 자정)
        schedule.every().day.at("00:00").do(self.daily_cleanup)
        
        # 주간 시스템 점검 (매주 일요일 오전 6시)
        schedule.every().sunday.at("06:00").do(self.weekly_maintenance)
        
        self.logger.info(f"📅 스케줄 설정 완료 - {interval}분마다 촬영, 활성 시간: {self.auto_config['active_hours']}")
    
    def is_active_time(self) -> bool:
        """현재 활성 시간인지 확인"""
        current_hour = datetime.now().hour
        start_hour, end_hour = self.auto_config["active_hours"]
        return start_hour <= current_hour < end_hour
    
    def can_capture_today(self) -> bool:
        """오늘 더 촬영할 수 있는지 확인"""
        today = datetime.now().strftime("%Y%m%d")
        count = self.daily_capture_count.get(today, 0)
        max_count = self.auto_config["max_daily_captures"]
        return count < max_count
    
    def scheduled_capture(self):
        """스케줄된 촬영 실행"""
        
        # 활성 시간 체크
        if not self.is_active_time():
            self.logger.debug("⏰ 비활성 시간대 - 촬영 건너뜀")
            return
        
        # 일일 촬영 제한 체크
        if not self.can_capture_today():
            self.logger.warning("📵 일일 촬영 제한 초과 - 촬영 건너뜀")
            return
        
        self.logger.info("🚀 자동 촬영 시작")
        
        # 모니터링 대상 식물 결정
        target_plants = self.auto_config["plants_to_monitor"]
        if not target_plants:
            target_plants = list(self.monitoring_system.config["plants"].keys())
        
        if not target_plants:
            self.logger.warning("🌱 등록된 식물이 없습니다 - 일반 촬영 실행")
            self._capture_single(None, "자동 촬영 - 일반")
            return
        
        # 각 식물별 촬영
        successful_captures = 0
        for plant_id in target_plants:
            try:
                result = self._capture_single(plant_id, "자동 촬영")
                if result:
                    successful_captures += 1
                    time.sleep(2)  # 촬영간 간격
            except Exception as e:
                self.logger.error(f"❌ {plant_id} 촬영 실패: {e}")
        
        # 일일 카운트 업데이트
        today = datetime.now().strftime("%Y%m%d")
        self.daily_capture_count[today] = self.daily_capture_count.get(today, 0) + successful_captures
        
        self.logger.info(f"✅ 자동 촬영 완료 - {successful_captures}/{len(target_plants)} 성공")
    
    def _capture_single(self, plant_id: str, notes: str) -> bool:
        """단일 촬영 수행"""
        try:
            result = self.monitoring_system.capture_image(plant_id, notes)
            if result:
                self.logger.info(f"📸 촬영 성공: {plant_id or 'general'} - {result['filename']}")
                return True
            else:
                self.logger.error(f"❌ 촬영 실패: {plant_id or 'general'}")
                return False
        except Exception as e:
            self.logger.error(f"❌ 촬영 오류: {plant_id or 'general'} - {e}")
            return False
    
    def daily_cleanup(self):
        """일일 정리 작업"""
        self.logger.info("🧹 일일 정리 작업 시작")
        
        # 일일 카운트 초기화
        today = datetime.now().strftime("%Y%m%d")
        yesterday = (datetime.now() - timedelta(days=1)).strftime("%Y%m%d")
        
        # 어제 통계 로그
        if yesterday in self.daily_capture_count:
            count = self.daily_capture_count[yesterday]
            self.logger.info(f"📊 어제 촬영 통계: {count}회")
            del self.daily_capture_count[yesterday]
        
        # 임시 파일 정리
        temp_dir = self.monitoring_system.base_path / "temp"
        if temp_dir.exists():
            for temp_file in temp_dir.glob("*"):
                if temp_file.is_file() and (datetime.now() - datetime.fromtimestamp(temp_file.stat().st_mtime)).days > 1:
                    temp_file.unlink()
                    self.logger.debug(f"🗑️ 임시 파일 삭제: {temp_file}")
        
        self.logger.info("✅ 일일 정리 완료")
    
    def weekly_maintenance(self):
        """주간 점검 및 유지보수"""
        self.logger.info("🔧 주간 점검 시작")
        
        # 시스템 통계 로그
        stats = self.monitoring_system.get_system_stats()
        self.logger.info(f"📊 시스템 통계:")
        self.logger.info(f"   등록된 식물: {stats['plants_registered']}개")
        self.logger.info(f"   총 이미지: {stats['total_images']}개")
        self.logger.info(f"   디스크 사용량: {stats['disk_usage']['usage_percent']:.1f}%")
        
        # 디스크 공간 경고
        if stats['disk_usage']['usage_percent'] > 85:
            self.logger.warning(f"⚠️ 디스크 공간 부족: {stats['disk_usage']['usage_percent']:.1f}% 사용중")
        
        # 오래된 파일 정리 (설정된 일수 이후)
        if self.auto_config["cleanup_days"] > 0:
            self.logger.info(f"🗂️ {self.auto_config['cleanup_days']}일 이전 파일 정리 시작")
            # 실제 정리는 안전상 수동으로 확인 후 실행하도록 권장
            self.logger.info("💡 수동 정리 권장: python3 -c \"from plant_monitoring_system import PlantMonitoringSystem; PlantMonitoringSystem().cleanup_old_files()\"")
        
        self.logger.info("✅ 주간 점검 완료")
    
    def start_monitoring(self):
        """모니터링 시작"""
        if self.is_running:
            self.logger.warning("⚠️ 모니터링이 이미 실행 중입니다")
            return
        
        self.is_running = True
        self.logger.info("🚀 자동 식물 모니터링 시작")
        
        # 백그라운드 스레드에서 스케줄 실행
        def run_scheduler():
            while self.is_running:
                try:
                    schedule.run_pending()
                    time.sleep(60)  # 1분마다 체크
                except Exception as e:
                    self.logger.error(f"❌ 스케줄러 오류: {e}")
                    time.sleep(60)
        
        self.scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
        self.scheduler_thread.start()
        
        self.logger.info("✅ 백그라운드 모니터링 시작됨")
    
    def stop_monitoring(self):
        """모니터링 중지"""
        if not self.is_running:
            self.logger.warning("⚠️ 모니터링이 실행되고 있지 않습니다")
            return
        
        self.is_running = False
        self.logger.info("🛑 자동 식물 모니터링 중지")
        
        # 스케줄 정리
        schedule.clear()
        self.logger.info("✅ 모니터링 중지 완료")
    
    def get_monitoring_status(self) -> dict:
        """모니터링 상태 조회"""
        today = datetime.now().strftime("%Y%m%d")
        
        status = {
            "is_running": self.is_running,
            "is_active_time": self.is_active_time(),
            "can_capture_today": self.can_capture_today(),
            "captures_today": self.daily_capture_count.get(today, 0),
            "max_daily_captures": self.auto_config["max_daily_captures"],
            "interval_minutes": self.auto_config["interval_minutes"],
            "active_hours": self.auto_config["active_hours"],
            "next_scheduled": self._get_next_scheduled_time()
        }
        
        return status
    
    def _get_next_scheduled_time(self) -> str:
        """다음 스케줄된 시간 조회"""
        try:
            next_job = schedule.next_run()
            if next_job:
                return next_job.strftime("%Y-%m-%d %H:%M:%S")
        except:
            pass
        return "알 수 없음"

def main():
    """메인 함수 - 자동 모니터링 제어"""
    
    print("🤖 자동 식물 모니터링 시스템")
    print("=" * 50)
    
    # 모니터링 시스템 초기화
    auto_monitor = AutomatedPlantMonitor()
    
    while True:
        print("\n📋 메뉴:")
        print("1. 모니터링 시작")
        print("2. 모니터링 중지") 
        print("3. 상태 확인")
        print("4. 설정 조정")
        print("5. 수동 촬영")
        print("6. 종료")
        
        choice = input("\n선택: ")
        
        if choice == "1":
            auto_monitor.start_monitoring()
            print("✅ 자동 모니터링이 시작되었습니다")
            print("💡 백그라운드에서 실행됩니다. 터미널을 종료하지 마세요.")
            
        elif choice == "2":
            auto_monitor.stop_monitoring()
            
        elif choice == "3":
            status = auto_monitor.get_monitoring_status()
            print(f"\n📊 모니터링 상태:")
            print(f"  실행 중: {'예' if status['is_running'] else '아니오'}")
            print(f"  활성 시간: {'예' if status['is_active_time'] else '아니오'}")
            print(f"  오늘 촬영: {status['captures_today']}/{status['max_daily_captures']}회")
            print(f"  촬영 간격: {status['interval_minutes']}분")
            print(f"  활성 시간대: {status['active_hours'][0]}시 ~ {status['active_hours'][1]}시")
            print(f"  다음 예정: {status['next_scheduled']}")
            
        elif choice == "4":
            print("\n⚙️ 설정 조정:")
            print("1. 촬영 간격 변경")
            print("2. 활성 시간 변경")
            print("3. 일일 촬영 제한 변경")
            
            setting_choice = input("선택: ")
            
            if setting_choice == "1":
                try:
                    new_interval = int(input("새로운 간격(분): "))
                    auto_monitor.auto_config["interval_minutes"] = new_interval
                    print(f"✅ 촬영 간격을 {new_interval}분으로 변경했습니다")
                except ValueError:
                    print("❌ 잘못된 입력입니다")
                    
            elif setting_choice == "2":
                try:
                    start_hour = int(input("시작 시간(24시간 형식): "))
                    end_hour = int(input("종료 시간(24시간 형식): "))
                    auto_monitor.auto_config["active_hours"] = (start_hour, end_hour)
                    print(f"✅ 활성 시간을 {start_hour}시~{end_hour}시로 변경했습니다")
                except ValueError:
                    print("❌ 잘못된 입력입니다")
                    
            elif setting_choice == "3":
                try:
                    max_captures = int(input("일일 최대 촬영 횟수: "))
                    auto_monitor.auto_config["max_daily_captures"] = max_captures
                    print(f"✅ 일일 촬영 제한을 {max_captures}회로 변경했습니다")
                except ValueError:
                    print("❌ 잘못된 입력입니다")
            
        elif choice == "5":
            # 수동 촬영
            plants = list(auto_monitor.monitoring_system.config["plants"].keys())
            if plants:
                print("등록된 식물:", plants)
                plant_id = input("식물 ID (엔터시 일반 촬영): ").strip()
            else:
                plant_id = None
            
            result = auto_monitor._capture_single(plant_id if plant_id else None, "수동 촬영")
            if result:
                print("✅ 수동 촬영 완료")
            else:
                print("❌ 수동 촬영 실패")
            
        elif choice == "6":
            auto_monitor.stop_monitoring()
            print("👋 시스템을 종료합니다")
            break
            
        else:
            print("❌ 잘못된 선택입니다")

if __name__ == "__main__":
    main()