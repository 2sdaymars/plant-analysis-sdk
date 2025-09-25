#!/usr/bin/env python3
"""
라즈베리파이 식물 모니터링 시스템
- 원본 이미지 중심 저장
- 식물별/시간별 체계적 분류
- 분석 데이터와 원본 이미지 분리
- 확장 가능한 데이터 구조
"""

import cv2
import numpy as np
import os
import json
from datetime import datetime, date
from pathlib import Path
import shutil
from typing import Dict, List, Optional, Tuple

class PlantMonitoringSystem:
    """식물 모니터링 시스템 메인 클래스"""
    
    def __init__(self, base_path: str = "/home/pi/plant_monitoring"):
        """
        시스템 초기화
        
        Args:
            base_path: 데이터 저장 기본 경로
        """
        self.base_path = Path(base_path)
        self.setup_directory_structure()
        self.config_file = self.base_path / "config.json"
        self.load_config()
    
    def setup_directory_structure(self):
        """체계적인 디렉토리 구조 생성"""
        
        # 기본 디렉토리 구조
        directories = [
            "raw_images",           # 원본 이미지 (절대 건드리지 않음)
            "raw_images/plants",    # 식물별 분류
            "analysis",            # 분석 결과
            "analysis/processed",  # 처리된 이미지
            "analysis/data",       # 분석 데이터 (JSON, CSV 등)
            "metadata",           # 메타데이터
            "logs",              # 로그 파일
            "temp",              # 임시 파일
        ]
        
        for directory in directories:
            (self.base_path / directory).mkdir(parents=True, exist_ok=True)
        
        print(f"📁 디렉토리 구조 생성 완료: {self.base_path}")
    
    def load_config(self):
        """설정 파일 로드"""
        
        default_config = {
            "plants": {},  # 등록된 식물들
            "camera_settings": {
                "width": 1920,
                "height": 1080,
                "quality": 95
            },
            "monitoring": {
                "interval_minutes": 60,
                "auto_analysis": True,
                "retain_days": 365
            },
            "analysis_settings": {
                "save_processed_images": True,
                "export_data": True
            }
        }
        
        if self.config_file.exists():
            with open(self.config_file, 'r', encoding='utf-8') as f:
                self.config = json.load(f)
        else:
            self.config = default_config
            self.save_config()
    
    def save_config(self):
        """설정 파일 저장"""
        with open(self.config_file, 'w', encoding='utf-8') as f:
            json.dump(self.config, f, indent=2, ensure_ascii=False)
    
    def register_plant(self, plant_name: str, plant_info: Dict = None) -> str:
        """
        식물 등록
        
        Args:
            plant_name: 식물 이름
            plant_info: 식물 추가 정보
            
        Returns:
            plant_id: 생성된 식물 ID
        """
        plant_id = plant_name.lower().replace(' ', '_')
        
        # 식물 전용 디렉토리 생성
        plant_dir = self.base_path / "raw_images" / "plants" / plant_id
        plant_dir.mkdir(parents=True, exist_ok=True)
        
        # 식물 정보 저장
        plant_data = {
            "name": plant_name,
            "id": plant_id,
            "registered_date": datetime.now().isoformat(),
            "info": plant_info or {},
            "image_count": 0,
            "last_captured": None
        }
        
        self.config["plants"][plant_id] = plant_data
        self.save_config()
        
        print(f"🌱 식물 등록 완료: {plant_name} (ID: {plant_id})")
        return plant_id
    
    def capture_image(self, plant_id: str = None, notes: str = "") -> Optional[Dict]:
        """
        이미지 촬영 및 체계적 저장
        
        Args:
            plant_id: 대상 식물 ID (없으면 일반 촬영)
            notes: 촬영 메모
            
        Returns:
            capture_info: 촬영 정보
        """
        print("📸 이미지 촬영 시작...")
        
        # 카메라 초기화
        cap = cv2.VideoCapture(0)
        
        if not cap.isOpened():
            print("❌ 카메라 연결 실패")
            return None
        
        # 카메라 설정 적용
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, self.config["camera_settings"]["width"])
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, self.config["camera_settings"]["height"])
        
        # 이미지 촬영
        ret, frame = cap.read()
        cap.release()
        
        if not ret:
            print("❌ 이미지 촬영 실패")
            return None
        
        # 촬영 시간 및 파일명 생성
        capture_time = datetime.now()
        timestamp = capture_time.strftime("%Y%m%d_%H%M%S")
        
        # 저장 경로 결정
        if plant_id and plant_id in self.config["plants"]:
            # 식물별 저장
            save_dir = self.base_path / "raw_images" / "plants" / plant_id / capture_time.strftime("%Y") / capture_time.strftime("%m")
            filename = f"{plant_id}_{timestamp}.jpg"
        else:
            # 일반 저장
            save_dir = self.base_path / "raw_images" / capture_time.strftime("%Y") / capture_time.strftime("%m")
            filename = f"capture_{timestamp}.jpg"
        
        save_dir.mkdir(parents=True, exist_ok=True)
        image_path = save_dir / filename
        
        # 고품질로 이미지 저장
        cv2.imwrite(str(image_path), frame, [
            cv2.IMWRITE_JPEG_QUALITY, self.config["camera_settings"]["quality"]
        ])
        
        # 메타데이터 생성
        metadata = {
            "filename": filename,
            "path": str(image_path.relative_to(self.base_path)),
            "absolute_path": str(image_path),
            "plant_id": plant_id,
            "plant_name": self.config["plants"].get(plant_id, {}).get("name", "Unknown") if plant_id else "General",
            "capture_time": capture_time.isoformat(),
            "timestamp": timestamp,
            "notes": notes,
            "camera_settings": self.config["camera_settings"].copy(),
            "image_properties": {
                "width": frame.shape[1],
                "height": frame.shape[0],
                "channels": frame.shape[2],
                "size_bytes": image_path.stat().st_size
            }
        }
        
        # 메타데이터 저장
        metadata_path = self.base_path / "metadata" / f"{timestamp}_metadata.json"
        with open(metadata_path, 'w', encoding='utf-8') as f:
            json.dump(metadata, f, indent=2, ensure_ascii=False)
        
        # 설정 업데이트
        if plant_id and plant_id in self.config["plants"]:
            self.config["plants"][plant_id]["image_count"] += 1
            self.config["plants"][plant_id]["last_captured"] = capture_time.isoformat()
            self.save_config()
        
        print(f"✅ 이미지 저장 완료:")
        print(f"   📁 경로: {image_path}")
        print(f"   📊 크기: {metadata['image_properties']['width']}x{metadata['image_properties']['height']}")
        print(f"   💾 용량: {metadata['image_properties']['size_bytes']/1024:.1f}KB")
        
        # 자동 분석 실행
        if self.config["monitoring"]["auto_analysis"]:
            self.analyze_image(str(image_path), metadata)
        
        return metadata
    
    def analyze_image(self, image_path: str, metadata: Dict = None) -> Optional[Dict]:
        """
        이미지 분석 (원본은 건드리지 않음)
        
        Args:
            image_path: 분석할 이미지 경로
            metadata: 이미지 메타데이터
            
        Returns:
            analysis_result: 분석 결과
        """
        print(f"🔍 이미지 분석 시작: {Path(image_path).name}")
        
        # 원본 이미지 읽기
        img = cv2.imread(image_path)
        if img is None:
            print("❌ 이미지 읽기 실패")
            return None
        
        analysis_time = datetime.now()
        timestamp = analysis_time.strftime("%Y%m%d_%H%M%S")
        
        # 분석 결과 저장 경로
        analysis_dir = self.base_path / "analysis" / "data" / analysis_time.strftime("%Y") / analysis_time.strftime("%m")
        analysis_dir.mkdir(parents=True, exist_ok=True)
        
        # 기본 분석 수행
        analysis_result = {
            "original_image": image_path,
            "analysis_time": analysis_time.isoformat(),
            "metadata": metadata,
            "analysis": {}
        }
        
        # 1. 기본 이미지 통계
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        analysis_result["analysis"]["basic_stats"] = {
            "mean_brightness": float(np.mean(gray)),
            "std_brightness": float(np.std(gray)),
            "min_brightness": int(np.min(gray)),
            "max_brightness": int(np.max(gray))
        }
        
        # 2. 색상 분석
        b_mean = float(np.mean(img[:, :, 0]))
        g_mean = float(np.mean(img[:, :, 1]))
        r_mean = float(np.mean(img[:, :, 2]))
        
        total_color = b_mean + g_mean + r_mean
        analysis_result["analysis"]["color_analysis"] = {
            "mean_bgr": [b_mean, g_mean, r_mean],
            "green_ratio": g_mean / total_color * 100 if total_color > 0 else 0,
            "red_ratio": r_mean / total_color * 100 if total_color > 0 else 0,
            "blue_ratio": b_mean / total_color * 100 if total_color > 0 else 0
        }
        
        # 3. 녹색 영역 분석 (식물 감지용)
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        lower_green = np.array([35, 40, 40])
        upper_green = np.array([85, 255, 255])
        green_mask = cv2.inRange(hsv, lower_green, upper_green)
        
        green_pixels = np.sum(green_mask > 0)
        total_pixels = img.shape[0] * img.shape[1]
        
        analysis_result["analysis"]["plant_detection"] = {
            "green_pixel_count": int(green_pixels),
            "total_pixels": int(total_pixels),
            "green_coverage_percent": float(green_pixels / total_pixels * 100),
            "plant_detected": green_pixels / total_pixels > 0.05  # 5% 이상이면 식물로 간주
        }
        
        # 4. 처리된 이미지 저장 (선택사항)
        if self.config["analysis_settings"]["save_processed_images"]:
            processed_dir = self.base_path / "analysis" / "processed" / analysis_time.strftime("%Y") / analysis_time.strftime("%m")
            processed_dir.mkdir(parents=True, exist_ok=True)
            
            # 녹색 마스크 오버레이 생성
            overlay = img.copy()
            overlay[green_mask > 0] = [0, 255, 0]  # 녹색 영역 강조
            result_img = cv2.addWeighted(img, 0.7, overlay, 0.3, 0)
            
            processed_path = processed_dir / f"analyzed_{timestamp}.jpg"
            cv2.imwrite(str(processed_path), result_img)
            analysis_result["processed_image"] = str(processed_path)
        
        # 분석 결과 저장
        analysis_file = analysis_dir / f"analysis_{timestamp}.json"
        with open(analysis_file, 'w', encoding='utf-8') as f:
            json.dump(analysis_result, f, indent=2, ensure_ascii=False)
        
        print("✅ 분석 완료:")
        print(f"   🌿 식물 감지: {'예' if analysis_result['analysis']['plant_detection']['plant_detected'] else '아니오'}")
        print(f"   💚 녹색 비율: {analysis_result['analysis']['color_analysis']['green_ratio']:.1f}%")
        print(f"   📊 분석 파일: {analysis_file}")
        
        return analysis_result
    
    def get_plant_timeline(self, plant_id: str, days: int = 30) -> List[Dict]:
        """
        식물의 시간별 이미지 타임라인 조회
        
        Args:
            plant_id: 식물 ID
            days: 조회할 일수
            
        Returns:
            timeline: 시간순 이미지 목록
        """
        if plant_id not in self.config["plants"]:
            print(f"❌ 등록되지 않은 식물: {plant_id}")
            return []
        
        plant_dir = self.base_path / "raw_images" / "plants" / plant_id
        timeline = []
        
        # 메타데이터 파일들 검색
        metadata_dir = self.base_path / "metadata"
        for metadata_file in metadata_dir.glob("*_metadata.json"):
            try:
                with open(metadata_file, 'r', encoding='utf-8') as f:
                    metadata = json.load(f)
                
                if metadata.get("plant_id") == plant_id:
                    # 날짜 필터링
                    capture_time = datetime.fromisoformat(metadata["capture_time"])
                    if (datetime.now() - capture_time).days <= days:
                        timeline.append(metadata)
            except Exception as e:
                continue
        
        # 시간순 정렬
        timeline.sort(key=lambda x: x["capture_time"])
        
        return timeline
    
    def cleanup_old_files(self, days: int = None):
        """오래된 파일 정리"""
        if days is None:
            days = self.config["monitoring"]["retain_days"]
        
        cutoff_date = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0) - \
                     datetime.timedelta(days=days)
        
        print(f"🧹 {days}일 이전 파일 정리 시작...")
        
        # TODO: 실제 파일 정리 로직 구현
        # (안전을 위해 주석 처리, 필요시 구현)
        
    def get_system_stats(self) -> Dict:
        """시스템 통계 조회"""
        stats = {
            "plants_registered": len(self.config["plants"]),
            "total_images": 0,
            "disk_usage": {},
            "recent_activity": []
        }
        
        # 이미지 개수 계산
        for plant_id, plant_info in self.config["plants"].items():
            stats["total_images"] += plant_info.get("image_count", 0)
        
        # 디스크 사용량
        import shutil
        total, used, free = shutil.disk_usage(self.base_path)
        stats["disk_usage"] = {
            "total_gb": total // (1024**3),
            "used_gb": used // (1024**3),
            "free_gb": free // (1024**3),
            "usage_percent": used / total * 100
        }
        
        return stats

def main():
    """메인 함수 - 사용 예시"""
    
    # 시스템 초기화
    monitor = PlantMonitoringSystem()
    
    print("🌱 라즈베리파이 식물 모니터링 시스템")
    print("=" * 50)
    
    while True:
        print("\n📋 메뉴:")
        print("1. 식물 등록")
        print("2. 이미지 촬영")
        print("3. 식물 타임라인 조회")
        print("4. 시스템 통계")
        print("5. 종료")
        
        choice = input("\n선택: ")
        
        if choice == "1":
            plant_name = input("식물 이름: ")
            plant_id = monitor.register_plant(plant_name)
            
        elif choice == "2":
            plants = list(monitor.config["plants"].keys())
            if plants:
                print("등록된 식물:", plants)
                plant_id = input("식물 ID (엔터시 일반 촬영): ").strip()
                if plant_id and plant_id not in plants:
                    print("❌ 등록되지 않은 식물입니다.")
                    continue
            else:
                plant_id = None
            
            notes = input("메모 (선택사항): ")
            monitor.capture_image(plant_id if plant_id else None, notes)
            
        elif choice == "3":
            plants = list(monitor.config["plants"].keys())
            if not plants:
                print("❌ 등록된 식물이 없습니다.")
                continue
                
            print("등록된 식물:", plants)
            plant_id = input("조회할 식물 ID: ")
            
            timeline = monitor.get_plant_timeline(plant_id)
            if timeline:
                print(f"\n📅 {plant_id} 타임라인 ({len(timeline)}개 이미지):")
                for i, item in enumerate(timeline[-5:], 1):  # 최근 5개만 표시
                    capture_time = datetime.fromisoformat(item["capture_time"])
                    print(f"  {i}. {capture_time.strftime('%Y-%m-%d %H:%M')} - {item['filename']}")
            else:
                print("📷 촬영된 이미지가 없습니다.")
                
        elif choice == "4":
            stats = monitor.get_system_stats()
            print(f"\n📊 시스템 통계:")
            print(f"  등록된 식물: {stats['plants_registered']}개")
            print(f"  총 이미지: {stats['total_images']}개")
            print(f"  디스크 사용량: {stats['disk_usage']['used_gb']}/{stats['disk_usage']['total_gb']}GB ({stats['disk_usage']['usage_percent']:.1f}%)")
            
        elif choice == "5":
            print("👋 시스템을 종료합니다.")
            break
        else:
            print("❌ 잘못된 선택입니다.")

if __name__ == "__main__":
    main()