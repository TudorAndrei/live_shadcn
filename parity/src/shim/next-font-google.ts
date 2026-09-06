type FontOptions = {
  subsets?: string[];
};

type FontResult = {
  className: string;
  style: { fontFamily: string };
};

export function Vazirmatn(_options: FontOptions = {}): FontResult {
  return {
    className: "font-vazirmatn",
    style: { fontFamily: '"Vazirmatn Variable", sans-serif' },
  };
}
