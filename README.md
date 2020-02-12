# kubeinception

[![asciicast](https://asciinema.org/a/300370.svg)](https://asciinema.org/a/300370)

> 당신의 limbo는 몇단계에서 올까요?

kubernetes 안에서 kubernetes는 몇단계 까지 실행될 수 있을까요?

아래를 실행시키면 확인 할 수 있습니다.

```
kubectl apply -f create-kind.yaml
```

## faq

> Q.  kind 클러스터 생성시 registry에서 이미지를 못땅겨 옵니다.

* 도메인 서버를 1.1.1.1 외의 다른 것으로 바꿔보세요.
  