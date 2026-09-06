import type { CSSProperties, ImgHTMLAttributes } from "react";

type Props = Omit<ImgHTMLAttributes<HTMLImageElement>, "src"> & {
  fill?: boolean;
  priority?: boolean;
  src: string | { src: string };
};

export default function Image({ fill, priority: _priority, src, style, ...props }: Props) {
  const fillStyle: CSSProperties | undefined = fill
    ? {
        position: "absolute",
        height: "100%",
        width: "100%",
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
        color: "transparent",
      }
    : undefined;

  return <img {...props} src={typeof src === "string" ? src : src.src} style={{ ...fillStyle, ...style }} />;
}
