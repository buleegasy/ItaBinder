import React from 'react';
import { Search, Plus, LayoutGrid, BarChart2 } from 'lucide-react';

/**
 * itabinder (养谷) - "My Showcase" (我的展柜) Design Reference
 * Matching the "Restrained 2D & Modular" concept from the reference image.
 */

const FilterTag = ({ label, active = false }: { label: string; active?: boolean }) => (
  <button
    className={`px-4 py-1.5 rounded-full text-sm font-medium whitespace-nowrap transition-all ${
      active
        ? 'bg-white text-gray-900 shadow-sm'
        : 'bg-transparent text-gray-600 hover:bg-gray-100/50'
    }`}
  >
    {label}
  </button>
);

interface CardProps {
  title: string;
  subtitle: string;
  tagText?: string;
  tagColor?: 'gray' | 'purple' | 'red' | 'green';
  image: string;
}

const MerchCard = ({ title, subtitle, tagText, tagColor = 'gray', image }: CardProps) => {
  const badgeColors = {
    gray: 'bg-gray-100 text-gray-600',
    purple: 'bg-purple-500 text-white',
    red: 'bg-red-500 text-white',
    green: 'bg-green-500 text-white',
  };

  return (
    <div className="bg-white rounded-[20px] p-2.5 shadow-sm flex flex-col gap-2.5 cursor-pointer active:scale-[0.98] transition-transform">
      <div className="aspect-square relative rounded-2xl overflow-hidden bg-gray-50 flex-shrink-0">
        <img
          src={image}
          alt={title}
          className="w-full h-full object-cover"
        />
      </div>
      <div className="px-1 flex flex-col gap-1 pb-1">
        <h3 className="text-[13px] font-semibold text-gray-900 leading-tight line-clamp-2">
          {title}
        </h3>
        <div className="flex items-center justify-between gap-1 mt-auto">
          <p className="text-[11px] font-medium text-gray-500 truncate">
            {subtitle}
          </p>
          {tagText && (
            <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded-md flex-shrink-0 ${badgeColors[tagColor]}`}>
              {tagText}
            </span>
          )}
        </div>
      </div>
    </div>
  );
};

const ShowcasePage = () => {
  const filters = ['全部', '五条悟', '原神', '排球少年!!'];
  const mockMerch: CardProps[] = [
    { title: '五条悟 (咒术回战)', subtitle: '五条悟 镭射吧唧', tagText: '1', tagColor: 'gray', image: 'https://images.unsplash.com/photo-1618336753974-aae8e04506aa?q=80&w=400&h=400&auto=format&fit=crop' },
    { title: '神里绫华 (原神)', subtitle: '神里绫华 镭射立牌', tagText: '2', tagColor: 'gray', image: 'https://images.unsplash.com/photo-1578632292335-df3abbb0d586?q=80&w=400&h=400&auto=format&fit=crop' },
    { title: '日向翔阳 (排球少年!!)', subtitle: '日向翔阳', tagText: '色纸', tagColor: 'purple', image: 'https://images.unsplash.com/photo-1541562232579-512a21360020?q=80&w=400&h=400&auto=format&fit=crop' },
    { title: '克劳德 (FF7R)', subtitle: '克劳德', tagText: '豆眼', tagColor: 'purple', image: 'https://images.unsplash.com/photo-1560972550-aba3456b5564?q=80&w=400&h=400&auto=format&fit=crop' },
  ];

  return (
    <div className="min-h-screen bg-[#F1F4F9] pb-28 relative">
      {/* Header */}
      <header className="pt-14 pb-4 px-5 sticky top-0 z-40 bg-[#F1F4F9]/90 backdrop-blur-md">
        <div className="flex items-center justify-between mb-5">
          <h1 className="text-2xl font-bold text-gray-900 tracking-tight">吃谷人日记</h1>
          <div className="flex items-center gap-2">
            <button className="flex items-center gap-1.5 bg-white px-3 py-1.5 rounded-full shadow-sm active:scale-95 transition-transform">
              <Search size={14} className="text-gray-500" />
              <span className="text-[13px] font-medium text-gray-600">搜索</span>
            </button>
            <button className="w-8 h-8 rounded-full bg-purple-500 text-white flex items-center justify-center shadow-sm active:scale-95 transition-transform">
              <Plus size={18} />
            </button>
          </div>
        </div>
        
        {/* Flat Tags */}
        <div className="flex gap-1 overflow-x-auto no-scrollbar pb-1">
          {filters.map((filter, idx) => (
            <FilterTag key={filter} label={filter} active={idx === 0} />
          ))}
        </div>
      </header>

      {/* Grid Content */}
      <main className="px-5">
        <div className="grid grid-cols-2 gap-3.5">
          {mockMerch.map((item, idx) => (
            <MerchCard key={idx} {...item} />
          ))}
        </div>
      </main>

      {/* Center-Floating Bottom Navigation */}
      <nav className="fixed bottom-0 w-full bg-white rounded-t-[32px] px-8 pt-4 pb-8 flex items-end justify-between z-50 shadow-[0_-10px_40px_rgba(0,0,0,0.04)]">
        {/* Left Tab */}
        <div className="flex flex-col items-center gap-1.5 text-purple-600 flex-1">
          <LayoutGrid size={24} strokeWidth={2.5} />
          <span className="text-[10px] font-bold">展柜</span>
        </div>

        {/* Center Floating Action Button */}
        <div className="flex flex-col items-center relative flex-1">
          <button className="absolute -top-14 w-14 h-14 bg-purple-500 rounded-full flex items-center justify-center shadow-lg border-4 border-[#F1F4F9] text-white active:scale-95 transition-transform">
            <Plus size={24} strokeWidth={2.5} />
          </button>
          <span className="text-[10px] font-bold text-gray-400 mt-2">录入</span>
        </div>

        {/* Right Tab */}
        <div className="flex flex-col items-center gap-1.5 text-gray-400 flex-1">
          <BarChart2 size={24} strokeWidth={2.5} />
          <span className="text-[10px] font-bold">统计发现</span>
        </div>
      </nav>
    </div>
  );
};

export default ShowcasePage;
