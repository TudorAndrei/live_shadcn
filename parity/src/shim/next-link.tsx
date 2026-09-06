import type { AnchorHTMLAttributes } from "react";

type Props = AnchorHTMLAttributes<HTMLAnchorElement> & {
  href: string | { pathname: string };
};

export default function Link({ href, ...props }: Props) {
  return <a {...props} href={typeof href === "string" ? href : href.pathname} />;
}
